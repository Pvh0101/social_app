# Biểu Đồ Activity Cho Ứng Dụng Social App - Mermaid

Tài liệu này chứa các biểu đồ activity mô tả luồng hoạt động của các chức năng chính trong ứng dụng Social App, được tạo bằng cú pháp Mermaid.

## 1. Biểu Đồ Activity - Đăng Ký Tài Khoản

```mermaid
flowchart TD
    Start([Bắt đầu]) --> InputInfo[Nhập thông tin đăng ký]
    InputInfo --> ValidateInfo{Kiểm tra thông tin}
    ValidateInfo -->|Không hợp lệ| ShowError[Hiển thị lỗi]
    ShowError --> InputInfo
    ValidateInfo -->|Hợp lệ| CreateAccount[Tạo tài khoản]
    CreateAccount --> SendVerification[Gửi email xác thực]
    SendVerification --> VerifyEmail{Xác thực email?}
    VerifyEmail -->|Không| WaitForVerification[Chờ xác thực]
    WaitForVerification --> VerifyEmail
    VerifyEmail -->|Có| AccountCreated[Tài khoản đã được tạo]
    AccountCreated --> InputProfile[Nhập thông tin cá nhân]
    InputProfile --> UploadAvatar[Tải lên ảnh đại diện]
    UploadAvatar --> ProfileComplete[Hoàn thành hồ sơ]
    ProfileComplete --> End([Kết thúc])
```

## 2. Biểu Đồ Activity - Đăng Nhập

```mermaid
flowchart TD
    Start([Bắt đầu]) --> InputCredentials[Nhập email và mật khẩu]
    InputCredentials --> ValidateCredentials{Kiểm tra thông tin}
    ValidateCredentials -->|Không hợp lệ| ShowError[Hiển thị lỗi]
    ShowError --> InputCredentials
    ValidateCredentials -->|Hợp lệ| CheckVerification{Email đã xác thực?}
    CheckVerification -->|Không| ShowVerificationMessage[Hiển thị thông báo xác thực]
    ShowVerificationMessage --> ResendVerification[Gửi lại email xác thực]
    ResendVerification --> End([Kết thúc])
    CheckVerification -->|Có| Login[Đăng nhập]
    Login --> SaveLoginStatus[Lưu trạng thái đăng nhập]
    SaveLoginStatus --> NavigateToHome[Chuyển đến trang chủ]
    NavigateToHome --> End
```

## 3. Biểu Đồ Activity - Tạo Bài Viết

```mermaid
flowchart TD
    Start([Bắt đầu]) --> OpenCreatePost[Mở giao diện tạo bài viết]
    OpenCreatePost --> InputContent[Nhập nội dung bài viết]
    InputContent --> AddMedia{Thêm media?}
    AddMedia -->|Không| SetPrivacy[Thiết lập quyền riêng tư]
    AddMedia -->|Có| SelectMediaType[Chọn loại media]
    SelectMediaType --> UploadMedia[Tải lên media]
    UploadMedia --> SetPrivacy
    SetPrivacy --> AddLocation{Thêm vị trí?}
    AddLocation -->|Không| ValidatePost{Kiểm tra bài viết}
    AddLocation -->|Có| SelectLocation[Chọn vị trí]
    SelectLocation --> ValidatePost
    ValidatePost -->|Không hợp lệ| ShowError[Hiển thị lỗi]
    ShowError --> InputContent
    ValidatePost -->|Hợp lệ| SubmitPost[Đăng bài viết]
    SubmitPost --> ProcessingPost[Xử lý bài viết]
    ProcessingPost --> PostCreated[Bài viết đã được tạo]
    PostCreated --> NavigateToFeed[Chuyển đến bảng tin]
    NavigateToFeed --> End([Kết thúc])
```

## 4. Biểu Đồ Activity - Gửi Lời Mời Kết Bạn

```mermaid
flowchart TD
    Start([Bắt đầu]) --> SearchUser[Tìm kiếm người dùng]
    SearchUser --> ViewProfile[Xem hồ sơ người dùng]
    ViewProfile --> CheckFriendStatus{Kiểm tra trạng thái bạn bè}
    CheckFriendStatus -->|Đã là bạn bè| ShowFriendOptions[Hiển thị tùy chọn bạn bè]
    CheckFriendStatus -->|Đã gửi lời mời| ShowPendingRequest[Hiển thị lời mời đang chờ]
    CheckFriendStatus -->|Chưa là bạn bè| SendRequest[Gửi lời mời kết bạn]
    SendRequest --> RequestSent[Lời mời đã được gửi]
    RequestSent --> NotifyUser[Thông báo cho người dùng]
    NotifyUser --> End([Kết thúc])
    ShowFriendOptions --> End
    ShowPendingRequest --> End
```

## 5. Biểu Đồ Activity - Chấp Nhận Lời Mời Kết Bạn

```mermaid
flowchart TD
    Start([Bắt đầu]) --> ViewFriendRequests[Xem danh sách lời mời kết bạn]
    ViewFriendRequests --> SelectRequest[Chọn lời mời]
    SelectRequest --> ViewSenderProfile{Xem hồ sơ người gửi?}
    ViewSenderProfile -->|Có| ShowSenderProfile[Hiển thị hồ sơ người gửi]
    ShowSenderProfile --> DecideRequest{Quyết định}
    ViewSenderProfile -->|Không| DecideRequest
    DecideRequest -->|Từ chối| RejectRequest[Từ chối lời mời]
    DecideRequest -->|Chấp nhận| AcceptRequest[Chấp nhận lời mời]
    RejectRequest --> RemoveRequest[Xóa lời mời]
    AcceptRequest --> CreateFriendship[Tạo mối quan hệ bạn bè]
    CreateFriendship --> NotifyUsers[Thông báo cho cả hai người dùng]
    RemoveRequest --> End([Kết thúc])
    NotifyUsers --> End
```

## 6. Biểu Đồ Activity - Gửi Tin Nhắn

```mermaid
flowchart TD
    Start([Bắt đầu]) --> OpenChatList[Mở danh sách chat]
    OpenChatList --> SelectChat{Chọn chat hiện có?}
    SelectChat -->|Có| OpenChat[Mở cuộc trò chuyện]
    SelectChat -->|Không| CreateNewChat[Tạo cuộc trò chuyện mới]
    CreateNewChat --> SelectUser[Chọn người dùng]
    SelectUser --> OpenChat
    OpenChat --> TypeMessage[Nhập tin nhắn]
    TypeMessage --> AddMedia{Thêm media?}
    AddMedia -->|Có| SelectMediaType[Chọn loại media]
    SelectMediaType --> UploadMedia[Tải lên media]
    UploadMedia --> SendMessage[Gửi tin nhắn]
    AddMedia -->|Không| SendMessage
    SendMessage --> MessageSent[Tin nhắn đã được gửi]
    MessageSent --> UpdateChatList[Cập nhật danh sách chat]
    UpdateChatList --> NotifyRecipient[Thông báo cho người nhận]
    NotifyRecipient --> End([Kết thúc])
```

## 7. Biểu Đồ Activity - Tạo Nhóm Chat

```mermaid
flowchart TD
    Start([Bắt đầu]) --> OpenChatList[Mở danh sách chat]
    OpenChatList --> SelectCreateGroup[Chọn tạo nhóm mới]
    SelectCreateGroup --> InputGroupName[Nhập tên nhóm]
    InputGroupName --> SelectMembers[Chọn thành viên]
    SelectMembers --> UploadGroupImage{Tải lên ảnh nhóm?}
    UploadGroupImage -->|Có| SelectImage[Chọn ảnh]
    SelectImage --> CreateGroup[Tạo nhóm]
    UploadGroupImage -->|Không| CreateGroup
    CreateGroup --> GroupCreated[Nhóm đã được tạo]
    GroupCreated --> OpenGroupChat[Mở cuộc trò chuyện nhóm]
    OpenGroupChat --> NotifyMembers[Thông báo cho thành viên]
    NotifyMembers --> End([Kết thúc])
```

## 8. Biểu Đồ Activity - Xem Thông Báo

```mermaid
flowchart TD
    Start([Bắt đầu]) --> OpenNotifications[Mở danh sách thông báo]
    OpenNotifications --> CheckNotifications{Có thông báo?}
    CheckNotifications -->|Không| ShowEmptyState[Hiển thị trạng thái trống]
    CheckNotifications -->|Có| DisplayNotifications[Hiển thị danh sách thông báo]
    DisplayNotifications --> SelectNotification{Chọn thông báo?}
    SelectNotification -->|Không| MarkAllRead{Đánh dấu tất cả đã đọc?}
    SelectNotification -->|Có| OpenNotification[Mở thông báo]
    OpenNotification --> MarkAsRead[Đánh dấu đã đọc]
    MarkAsRead --> NavigateToContent[Chuyển đến nội dung liên quan]
    NavigateToContent --> End([Kết thúc])
    MarkAllRead -->|Có| MarkAllNotifications[Đánh dấu tất cả thông báo đã đọc]
    MarkAllRead -->|Không| End
    MarkAllNotifications --> End
    ShowEmptyState --> End
```

## 9. Biểu Đồ Activity - Chỉnh Sửa Hồ Sơ

```mermaid
flowchart TD
    Start([Bắt đầu]) --> OpenProfile[Mở hồ sơ cá nhân]
    OpenProfile --> SelectEdit[Chọn chỉnh sửa hồ sơ]
    SelectEdit --> EditInfo[Chỉnh sửa thông tin cá nhân]
    EditInfo --> ChangeAvatar{Thay đổi ảnh đại diện?}
    ChangeAvatar -->|Có| SelectImage[Chọn ảnh mới]
    SelectImage --> UploadImage[Tải lên ảnh]
    UploadImage --> ValidateChanges{Kiểm tra thay đổi}
    ChangeAvatar -->|Không| ValidateChanges
    ValidateChanges -->|Không hợp lệ| ShowError[Hiển thị lỗi]
    ShowError --> EditInfo
    ValidateChanges -->|Hợp lệ| SaveChanges[Lưu thay đổi]
    SaveChanges --> UpdateProfile[Cập nhật hồ sơ]
    UpdateProfile --> ProfileUpdated[Hồ sơ đã được cập nhật]
    ProfileUpdated --> End([Kết thúc])
```

## 10. Biểu Đồ Activity - Xóa Bài Viết

```mermaid
flowchart TD
    Start([Bắt đầu]) --> OpenProfile[Mở hồ sơ cá nhân]
    OpenProfile --> ViewPosts[Xem danh sách bài viết]
    ViewPosts --> SelectPost[Chọn bài viết]
    SelectPost --> OpenOptions[Mở tùy chọn bài viết]
    OpenOptions --> SelectDelete[Chọn xóa bài viết]
    SelectDelete --> ConfirmDelete{Xác nhận xóa?}
    ConfirmDelete -->|Không| CancelDelete[Hủy xóa]
    ConfirmDelete -->|Có| DeletePost[Xóa bài viết]
    DeletePost --> RemoveMedia[Xóa media liên quan]
    RemoveMedia --> RemoveComments[Xóa bình luận]
    RemoveComments --> RemoveLikes[Xóa lượt thích]
    RemoveLikes --> PostDeleted[Bài viết đã được xóa]
    PostDeleted --> UpdateFeed[Cập nhật bảng tin]
    UpdateFeed --> End([Kết thúc])
    CancelDelete --> End
```

## 11. Biểu Đồ Activity - Quản Lý Nhóm Chat

```mermaid
flowchart TD
    Start([Bắt đầu]) --> OpenGroupChat[Mở cuộc trò chuyện nhóm]
    OpenGroupChat --> OpenGroupInfo[Mở thông tin nhóm]
    OpenGroupInfo --> CheckRole{Kiểm tra vai trò}
    CheckRole -->|Thành viên| MemberOptions[Hiển thị tùy chọn thành viên]
    CheckRole -->|Quản trị viên| AdminOptions[Hiển thị tùy chọn quản trị viên]
    
    MemberOptions --> ViewMembers1[Xem thành viên]
    MemberOptions --> LeaveGroup[Rời khỏi nhóm]
    
    AdminOptions --> ViewMembers2[Xem thành viên]
    AdminOptions --> EditGroupName[Chỉnh sửa tên nhóm]
    AdminOptions --> ChangeGroupImage[Thay đổi ảnh nhóm]
    AdminOptions --> ManageMembers[Quản lý thành viên]
    AdminOptions --> DeleteGroup[Xóa nhóm]
    
    ManageMembers --> AddMember[Thêm thành viên]
    ManageMembers --> RemoveMember[Xóa thành viên]
    
    LeaveGroup --> ConfirmLeave{Xác nhận rời nhóm?}
    ConfirmLeave -->|Không| CancelLeave[Hủy rời nhóm]
    ConfirmLeave -->|Có| UserLeaves[Người dùng rời nhóm]
    
    DeleteGroup --> ConfirmDelete{Xác nhận xóa nhóm?}
    ConfirmDelete -->|Không| CancelDelete[Hủy xóa nhóm]
    ConfirmDelete -->|Có| GroupDeleted[Nhóm đã bị xóa]
    
    ViewMembers1 --> End([Kết thúc])
    ViewMembers2 --> End
    EditGroupName --> End
    ChangeGroupImage --> End
    AddMember --> End
    RemoveMember --> End
    CancelLeave --> End
    UserLeaves --> End
    CancelDelete --> End
    GroupDeleted --> End
```

## 12. Biểu Đồ Activity - Tìm Kiếm Người Dùng

```mermaid
flowchart TD
    Start([Bắt đầu]) --> OpenSearch[Mở tìm kiếm]
    OpenSearch --> InputQuery[Nhập từ khóa tìm kiếm]
    InputQuery --> PerformSearch[Thực hiện tìm kiếm]
    PerformSearch --> CheckResults{Có kết quả?}
    CheckResults -->|Không| ShowEmptyState[Hiển thị trạng thái trống]
    CheckResults -->|Có| DisplayResults[Hiển thị kết quả tìm kiếm]
    DisplayResults --> SelectUser{Chọn người dùng?}
    SelectUser -->|Không| End([Kết thúc])
    SelectUser -->|Có| ViewUserProfile[Xem hồ sơ người dùng]
    ViewUserProfile --> CheckFriendStatus{Kiểm tra trạng thái bạn bè}
    CheckFriendStatus -->|Đã là bạn bè| ShowFriendOptions[Hiển thị tùy chọn bạn bè]
    CheckFriendStatus -->|Đã gửi lời mời| ShowPendingRequest[Hiển thị lời mời đang chờ]
    CheckFriendStatus -->|Chưa là bạn bè| ShowAddFriend[Hiển thị nút thêm bạn bè]
    ShowFriendOptions --> End
    ShowPendingRequest --> End
    ShowAddFriend --> End
    ShowEmptyState --> End
```

## 13. Biểu Đồ Activity - Bình Luận Bài Viết

```mermaid
flowchart TD
    Start([Bắt đầu]) --> ViewPost[Xem bài viết]
    ViewPost --> OpenComments[Mở phần bình luận]
    OpenComments --> InputComment[Nhập nội dung bình luận]
    InputComment --> AddMedia{Thêm media?}
    AddMedia -->|Có| SelectMedia[Chọn media]
    SelectMedia --> UploadMedia[Tải lên media]
    UploadMedia --> SubmitComment[Gửi bình luận]
    AddMedia -->|Không| SubmitComment
    SubmitComment --> CommentAdded[Bình luận đã được thêm]
    CommentAdded --> UpdateCommentList[Cập nhật danh sách bình luận]
    UpdateCommentList --> NotifyPostOwner[Thông báo cho chủ bài viết]
    NotifyPostOwner --> End([Kết thúc])
```

## 14. Biểu Đồ Activity - Cài Đặt Quyền Riêng Tư

```mermaid
flowchart TD
    Start([Bắt đầu]) --> OpenSettings[Mở cài đặt]
    OpenSettings --> SelectPrivacy[Chọn cài đặt quyền riêng tư]
    SelectPrivacy --> ConfigureProfile{Cấu hình hồ sơ}
    ConfigureProfile --> SetProfileVisibility[Thiết lập quyền xem hồ sơ]
    ConfigureProfile --> ConfigurePosts{Cấu hình bài viết}
    ConfigurePosts --> SetPostsVisibility[Thiết lập quyền xem bài viết]
    ConfigurePosts --> ConfigureMessages{Cấu hình tin nhắn}
    ConfigureMessages --> SetMessagePermissions[Thiết lập quyền nhắn tin]
    SetMessagePermissions --> SaveSettings[Lưu cài đặt]
    SaveSettings --> SettingsSaved[Cài đặt đã được lưu]
    SettingsSaved --> End([Kết thúc])
```

## 15. Biểu Đồ Activity - Xem Bảng Tin

```mermaid
flowchart TD
    Start([Bắt đầu]) --> OpenApp[Mở ứng dụng]
    OpenApp --> CheckLogin{Đã đăng nhập?}
    CheckLogin -->|Không| NavigateToLogin[Chuyển đến đăng nhập]
    CheckLogin -->|Có| LoadFeed[Tải bảng tin]
    LoadFeed --> DisplayPosts[Hiển thị bài viết]
    DisplayPosts --> InteractWithPost{Tương tác với bài viết?}
    InteractWithPost -->|Không| ScrollFeed{Cuộn bảng tin?}
    InteractWithPost -->|Có| SelectInteraction[Chọn loại tương tác]
    SelectInteraction --> LikePost[Thích bài viết]
    SelectInteraction --> CommentPost[Bình luận bài viết]
    SelectInteraction --> SharePost[Chia sẻ bài viết]
    SelectInteraction --> ViewPostDetail[Xem chi tiết bài viết]
    LikePost --> UpdateLikeStatus[Cập nhật trạng thái thích]
    CommentPost --> OpenCommentSection[Mở phần bình luận]
    SharePost --> OpenShareOptions[Mở tùy chọn chia sẻ]
    ViewPostDetail --> NavigateToPost[Chuyển đến trang bài viết]
    UpdateLikeStatus --> DisplayPosts
    OpenCommentSection --> DisplayPosts
    OpenShareOptions --> DisplayPosts
    NavigateToPost --> End([Kết thúc])
    ScrollFeed -->|Có| LoadMorePosts{Tải thêm bài viết?}
    ScrollFeed -->|Không| End
    LoadMorePosts -->|Có| FetchMorePosts[Tải thêm bài viết]
    LoadMorePosts -->|Không| End
    FetchMorePosts --> DisplayPosts
    NavigateToLogin --> End
``` 