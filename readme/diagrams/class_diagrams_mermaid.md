# Biểu Đồ Lớp (Class Diagram) Cho Ứng Dụng Social App - Mermaid

Tài liệu này chứa các biểu đồ lớp chi tiết cho các thành phần chính của ứng dụng Social App, được tổ chức theo các module chức năng và sử dụng cú pháp Mermaid.

## 1. Biểu Đồ Lớp - Module Xác Thực (Authentication)

```mermaid
classDiagram
    class UserModel {
        -String uid
        -String? token
        -String email
        -String fullName
        -String? gender
        -DateTime? birthDay
        -String? phoneNumber
        -String? address
        -String? profileImage
        -String? decs
        -DateTime? lastSeen
        -DateTime? createdAt
        -bool isOnline
        -bool isPrivateAccount
        -int followersCount
        +bool isProfileComplete()
        +Map~String, dynamic~ toMap()
        +UserModel fromMap(Map~String, dynamic~)
        +UserModel fromDocument(DocumentSnapshot)
        +UserModel copyWith(...)
        +String lastSeenText()
    }

    class AuthRepository {
        -FirebaseAuth _firebaseAuth
        -FirebaseFirestore _firestore
        -FirebaseStorage _storage
        +Future~UserCredential~ registerUser(String email, String password)
        +Future~void~ sendEmailVerification()
        +Future~void~ createUserDocument(String userId, Map~String, dynamic~ data)
        +Future~UserCredential~ loginUser(String email, String password)
        +Future~void~ logoutUser()
        +Future~void~ updateUserProfile(String userId, Map~String, dynamic~ data, File? avatar)
        +Future~void~ updateUserStatus(String userId, bool isOnline)
        +Future~void~ updateFCMToken(String userId, String token)
        +Future~void~ resetPassword(String email)
        +Future~UserModel?~ getCurrentUser()
        +Stream~UserModel?~ userStream(String userId)
    }

    class AuthProvider {
        -AuthRepository _authRepository
        -UserModel? _currentUser
        -AuthStatus _status
        +UserModel? currentUser()
        +AuthStatus status()
        +Future~void~ registerUser(String email, String password)
        +Future~void~ loginUser(String email, String password)
        +Future~void~ logoutUser()
        +Future~void~ updateUserProfile(Map~String, dynamic~ data, File? avatar)
        +Future~void~ resetPassword(String email)
        +Future~void~ checkAuthStatus()
        +Future~void~ updateUserStatus(bool isOnline)
        +Future~void~ updateFCMToken(String token)
    }

    class AuthStatus {
        <<enumeration>>
        INITIAL
        AUTHENTICATED
        UNAUTHENTICATED
        LOADING
    }

    AuthRepository --> UserModel : creates
    AuthProvider --> AuthRepository : uses
```

## 2. Biểu Đồ Lớp - Module Bài Viết (Posts)

```mermaid
classDiagram
    class PostModel {
        -String postId
        -String userId
        -String content
        -List~String~? fileUrls
        -String? thumbnailUrl
        -PostType postType
        -DateTime createdAt
        -DateTime? updatedAt
        -int likeCount
        -int commentCount
        +Map~String, dynamic~ toMap()
        +PostModel fromMap(Map~String, dynamic~)
        +String createdAtText()
        +String updatedAtText()
    }
    
    class CommentModel {
        -String id
        -String postId
        -String userId
        -String content
        -DateTime createdAt
        +Map~String, dynamic~ toMap()
        +CommentModel fromMap(Map~String, dynamic~)
    }
    
    class LikeModel {
        -String id
        -String postId
        -String userId
        -DateTime createdAt
        +Map~String, dynamic~ toMap()
        +LikeModel fromMap(Map~String, dynamic~)
    }
    
    class PostType {
        <<enumeration>>
        TEXT
        IMAGE
        VIDEO
        +String value()
        +PostType fromString(String value)
    }
    
    class PostRepository {
        -FirebaseFirestore _firestore
        -FirebaseStorage _storage
        +Future~List~PostModel~~ getPosts(String userId, int limit, String? lastPostId)
        +Future~PostModel~ getPost(String postId)
        +Future~String~ createPost(String userId, String content, List~File~? mediaFiles, PostType type)
        +Future~void~ updatePost(String postId, String newContent)
        +Future~void~ deletePost(String postId)
        +Future~void~ likePost(String postId, String userId)
        +Future~void~ unlikePost(String postId, String userId)
        +Future~List~CommentModel~~ getComments(String postId, int limit, String? lastCommentId)
        +Future~String~ addComment(String postId, String userId, String content)
        +Future~void~ deleteComment(String commentId)
        +Future~List~LikeModel~~ getLikes(String postId, int limit, String? lastLikeId)
        +Future~bool~ isPostLiked(String postId, String userId)
        +Stream~PostModel~ postStream(String postId)
        +Stream~List~PostModel~~ userPostsStream(String userId, int limit)
    }
    
    class PostsProvider {
        -PostRepository _postRepository
        -List~PostModel~ _posts
        -bool _hasMore
        -bool _isLoading
        +List~PostModel~ posts()
        +bool hasMore()
        +bool isLoading()
        +Future~void~ getPosts(int limit, String? lastPostId)
        +Future~void~ refreshPosts()
        +Future~void~ loadMorePosts()
        +Future~void~ createPost(String content, List~File~? mediaFiles, PostType type)
        +Future~void~ updatePost(String postId, String newContent)
        +Future~void~ deletePost(String postId)
        +Future~void~ likePost(String postId)
        +Future~void~ unlikePost(String postId)
        +Future~List~CommentModel~~ getComments(String postId, int limit, String? lastCommentId)
        +Future~void~ addComment(String postId, String content)
        +Future~void~ deleteComment(String commentId)
        +Future~List~LikeModel~~ getLikes(String postId, int limit, String? lastLikeId)
        +Future~bool~ isPostLiked(String postId)
    }

    PostModel "1" --> "0..*" CommentModel : has
    PostModel "1" --> "0..*" LikeModel : has
    PostRepository --> PostModel : manages
    PostRepository --> CommentModel : manages
    PostRepository --> LikeModel : manages
    PostsProvider --> PostRepository : uses
```

## 3. Biểu Đồ Lớp - Module Nhắn Tin (Chat)

```mermaid
classDiagram
    class Chatroom {
        -String id
        -List~String~ participantIds
        -String? groupName
        -String? groupImage
        -bool isGroup
        -DateTime lastMessageTime
        -String lastMessageText
        -String lastMessageSenderId
        -Map~String, DateTime~ readStatus
        +Map~String, dynamic~ toMap()
        +Chatroom fromMap(Map~String, dynamic~)
    }
    
    class Message {
        -String id
        -String chatId
        -String senderId
        -String? senderName
        -String? senderAvatar
        -String content
        -MessageType type
        -String? mediaUrl
        -Set~String~ seenBy
        -DateTime createdAt
        +bool isSeenBy(String userId)
        +String getDisplayContent()
        +String createdAtText()
        +Map~String, dynamic~ toMap()
        +Message fromMap(Map~String, dynamic~)
    }
    
    class MessageType {
        <<enumeration>>
        TEXT
        IMAGE
        VIDEO
        FILE
        AUDIO
        LOCATION
        +String displayText()
        +MessageType fromString(String value)
    }
    
    class ChatRepository {
        -FirebaseFirestore _firestore
        -FirebaseStorage _storage
        +Future~List~Chatroom~~ getChats(String userId)
        +Future~Chatroom~ getChat(String chatId)
        +Future~String~ createChat(List~String~ participantIds)
        +Future~String~ createGroupChat(String name, List~String~ members, String creatorId, File? avatar)
        +Future~List~Message~~ getMessages(String chatId, int limit, String? lastMessageId)
        +Future~String~ sendMessage(String chatId, String content, String senderId)
        +Future~String~ sendMediaMessage(String chatId, File file, String senderId, MessageType type)
        +Future~void~ markMessagesAsRead(String chatId, String userId)
        +Future~void~ addMember(String chatId, String userId)
        +Future~void~ removeMember(String chatId, String userId)
        +Future~void~ leaveGroup(String chatId, String userId)
        +Future~void~ updateGroupInfo(String chatId, String? name, File? avatar)
        +Future~void~ deleteGroup(String chatId)
        +Stream~Chatroom~ chatStream(String chatId)
        +Stream~List~Message~~ messagesStream(String chatId, int limit)
        +Stream~List~Chatroom~~ userChatsStream(String userId)
    }
    
    class ChatProvider {
        -ChatRepository _chatRepository
        -List~Chatroom~ _chats
        -Chatroom? _currentChat
        -List~Message~ _messages
        -bool _hasMore
        -bool _isLoading
        +List~Chatroom~ chats()
        +Chatroom? currentChat()
        +List~Message~ messages()
        +bool hasMore()
        +bool isLoading()
        +Future~void~ getChats()
        +Future~void~ setCurrentChat(String chatId)
        +Future~void~ getMessages(int limit, String? lastMessageId)
        +Future~void~ loadMoreMessages()
        +Future~void~ sendMessage(String content)
        +Future~void~ sendMediaMessage(File file, MessageType type)
        +Future~void~ createChat(String userId)
        +Future~void~ createGroupChat(String name, List~String~ members, File? avatar)
        +Future~void~ markMessagesAsRead()
        +Future~void~ addMember(String userId)
        +Future~void~ removeMember(String userId)
        +Future~void~ leaveGroup()
        +Future~void~ updateGroupInfo(String? name, File? avatar)
        +Future~void~ deleteGroup()
    }

    Chatroom "1" --> "0..*" Message : contains
    ChatRepository --> Chatroom : manages
    ChatRepository --> Message : manages
    ChatProvider --> ChatRepository : uses
```

## 4. Biểu Đồ Lớp - Module Bạn Bè (Friends)

```mermaid
classDiagram
    class FriendshipModel {
        -String friendshipId
        -String senderId
        -String receiverId
        -bool isAccepted
        -DateTime createdAt
        +Map~String, dynamic~ toMap()
        +FriendshipModel fromMap(Map~String, dynamic~)
        +FriendshipModel fromDocument(DocumentSnapshot)
        +FriendshipModel copyWith(...)
        +String createdAtText()
    }
    
    class FriendRepository {
        -FirebaseFirestore _firestore
        +Future~List~UserModel~~ getFriends(String userId)
        +Future~List~UserModel~~ searchUsers(String query)
        +Future~void~ sendFriendRequest(String currentUserId, String targetUserId)
        +Future~List~FriendshipModel~~ getFriendRequests(String userId)
        +Future~void~ acceptFriendRequest(String requestId, String currentUserId, String senderId)
        +Future~void~ rejectFriendRequest(String requestId)
        +Future~void~ cancelFriendRequest(String requestId)
        +Future~void~ removeFriend(String currentUserId, String friendId)
        +Future~bool~ areFriends(String user1Id, String user2Id)
        +Future~FriendshipModel?~ getFriendRequestStatus(String user1Id, String user2Id)
        +Stream~List~UserModel~~ friendsStream(String userId)
        +Stream~List~FriendshipModel~~ friendRequestsStream(String userId)
    }
    
    class FriendsProvider {
        -FriendRepository _friendRepository
        -List~UserModel~ _friends
        -List~FriendshipModel~ _friendRequests
        -List~UserModel~ _searchResults
        -bool _isLoading
        +List~UserModel~ friends()
        +List~FriendshipModel~ friendRequests()
        +List~UserModel~ searchResults()
        +bool isLoading()
        +Future~void~ getFriends()
        +Future~void~ getFriendRequests()
        +Future~void~ searchUsers(String query)
        +Future~void~ sendFriendRequest(String targetUserId)
        +Future~void~ acceptFriendRequest(String requestId, String senderId)
        +Future~void~ rejectFriendRequest(String requestId)
        +Future~void~ cancelFriendRequest(String requestId)
        +Future~void~ removeFriend(String friendId)
        +Future~bool~ areFriends(String userId)
        +Future~FriendshipModel?~ getFriendRequestStatus(String userId)
    }

    UserModel "1" --> "0..*" FriendshipModel : has
    FriendRepository --> FriendshipModel : manages
    FriendsProvider --> FriendRepository : uses
```

## 5. Biểu Đồ Lớp - Module Thông Báo (Notifications)

```mermaid
classDiagram
    class NotificationModel {
        -String id
        -String senderId
        -String receiverId
        -String content
        -NotificationType type
        -String? postId
        -String? commentId
        -String? chatId
        -bool isRead
        -DateTime createdAt
        -String? senderName
        -String? senderAvatar
        +Map~String, dynamic~ toMap()
        +NotificationModel fromMap(Map~String, dynamic~)
        +String createdAtText()
        +NotificationModel copyWith(...)
    }
    
    class NotificationType {
        <<enumeration>>
        MESSAGE
        LIKE
        COMMENT
        MENTION
        FRIEND_REQUEST
        FRIEND_ACCEPT
        +String value()
        +NotificationType fromMap(Map~String, dynamic~ map)
    }
    
    class NotificationRepository {
        -FirebaseFirestore _firestore
        +Future~List~NotificationModel~~ getNotifications(String userId, int limit, String? lastNotificationId)
        +Future~void~ markNotificationAsRead(String notificationId)
        +Future~void~ markAllNotificationsAsRead(String userId)
        +Future~void~ createNotification(Map~String, dynamic~ notificationData)
        +Future~void~ deleteNotification(String notificationId)
        +Future~int~ getUnreadCount(String userId)
        +Stream~List~NotificationModel~~ notificationsStream(String userId, int limit)
        +Stream~int~ unreadCountStream(String userId)
    }
    
    class FCMService {
        -FirebaseMessaging _firebaseMessaging
        +Future~void~ initialize()
        +Future~String?~ getToken()
        +void configureMessageHandling()
        +Future~void~ subscribeToTopic(String topic)
        +Future~void~ unsubscribeFromTopic(String topic)
        +Future~void~ sendNotification(String token, String title, String body, Map~String, dynamic~ data)
    }
    
    class NotificationProvider {
        -NotificationRepository _notificationRepository
        -FCMService _fcmService
        -List~NotificationModel~ _notifications
        -int _unreadCount
        -bool _hasMore
        -bool _isLoading
        +List~NotificationModel~ notifications()
        +int unreadCount()
        +bool hasMore()
        +bool isLoading()
        +Future~void~ getNotifications(int limit, String? lastNotificationId)
        +Future~void~ loadMoreNotifications()
        +Future~void~ markNotificationAsRead(String notificationId)
        +Future~void~ markAllNotificationsAsRead()
        +Future~void~ getUnreadCount()
        +Future~void~ initializeFCM()
        +Future~void~ updateFCMToken()
    }

    UserModel "1" --> "0..*" NotificationModel : receives
    NotificationRepository --> NotificationModel : manages
    NotificationProvider --> NotificationRepository : uses
    NotificationProvider --> FCMService : uses
```

## 6. Biểu Đồ Lớp - Module Hồ Sơ (Profile)

```mermaid
classDiagram
    class ProfileRepository {
        -FirebaseFirestore _firestore
        -FirebaseStorage _storage
        -PostRepository _postRepository
        +Future~UserModel~ getUserProfile(String userId)
        +Future~List~PostModel~~ getUserPosts(String userId, int limit, String? lastPostId)
        +Future~void~ updateProfile(String userId, Map~String, dynamic~ data, File? avatar)
        +Future~void~ updatePrivacySettings(String userId, Map~String, dynamic~ settings)
        +Future~Map~String, dynamic~~ getPrivacySettings(String userId)
        +Stream~UserModel~ userProfileStream(String userId)
    }
    
    class ProfileProvider {
        -ProfileRepository _profileRepository
        -UserModel? _user
        -List~PostModel~ _userPosts
        -Map~String, dynamic~? _privacySettings
        -bool _hasMore
        -bool _isLoading
        +UserModel? user()
        +List~PostModel~ userPosts()
        +Map~String, dynamic~? privacySettings()
        +bool hasMore()
        +bool isLoading()
        +Future~void~ getUserProfile(String userId)
        +Future~void~ getUserPosts(String userId, int limit, String? lastPostId)
        +Future~void~ loadMoreUserPosts()
        +Future~void~ updateProfile(Map~String, dynamic~ profileData, File? avatar)
        +Future~void~ updatePrivacySettings(Map~String, dynamic~ settings)
        +Future~void~ getPrivacySettings()
    }

    ProfileRepository --> UserModel : retrieves
    ProfileRepository --> PostModel : retrieves
    ProfileProvider --> ProfileRepository : uses
```

## 7. Biểu Đồ Lớp Tổng Quan - Mối Quan Hệ Giữa Các Module

```mermaid
classDiagram
    class UserModel
    class PostModel
    class CommentModel
    class LikeModel
    class Chatroom
    class Message
    class FriendshipModel
    class NotificationModel
    
    class AuthStatus
    class PostType
    class MessageType
    class NotificationType
    
    class AuthRepository
    class PostRepository
    class ChatRepository
    class FriendRepository
    class NotificationRepository
    class ProfileRepository
    
    class AuthProvider
    class PostsProvider
    class ChatProvider
    class FriendsProvider
    class NotificationProvider
    class ProfileProvider
    
    class FCMService

    %% Mối quan hệ giữa các model
    UserModel "1" --> "0..*" PostModel : creates
    UserModel "1" --> "0..*" CommentModel : creates
    UserModel "1" --> "0..*" LikeModel : creates
    UserModel "1" --> "0..*" Message : sends
    UserModel "1" --> "0..*" FriendshipModel : has
    UserModel "1" --> "0..*" NotificationModel : receives
    PostModel "1" --> "0..*" CommentModel : has
    PostModel "1" --> "0..*" LikeModel : has
    Chatroom "1" --> "0..*" Message : contains
    Chatroom "1" --> "2..*" UserModel : involves

    %% Mối quan hệ giữa repositories và models
    AuthRepository --> UserModel : manages
    PostRepository --> PostModel : manages
    PostRepository --> CommentModel : manages
    PostRepository --> LikeModel : manages
    ChatRepository --> Chatroom : manages
    ChatRepository --> Message : manages
    FriendRepository --> FriendshipModel : manages
    NotificationRepository --> NotificationModel : manages
    ProfileRepository --> UserModel : manages

    %% Mối quan hệ giữa providers và repositories
    AuthProvider --> AuthRepository : uses
    PostsProvider --> PostRepository : uses
    ChatProvider --> ChatRepository : uses
    FriendsProvider --> FriendRepository : uses
    NotificationProvider --> NotificationRepository : uses
    NotificationProvider --> FCMService : uses
    ProfileProvider --> ProfileRepository : uses
```

## 8. Biểu Đồ Lớp - Cấu Trúc Dữ Liệu Firebase

```mermaid
classDiagram
    class Users {
        +String uid
        +String email
        +String fullName
        +String? gender
        +Timestamp? birthDay
        +String? phoneNumber
        +String? address
        +String? profileImage
        +String? decs
        +Timestamp? lastSeen
        +Timestamp? createdAt
        +bool isOnline
        +bool isPrivateAccount
        +int followersCount
        +String? token
    }
    
    class Posts {
        +String postId
        +String userId
        +String content
        +List~String~? fileUrls
        +String? thumbnailUrl
        +String postType
        +Timestamp createdAt
        +Timestamp? updatedAt
        +int likeCount
        +int commentCount
    }
    
    class Comments {
        +String id
        +String postId
        +String userId
        +String content
        +Timestamp createdAt
    }
    
    class Likes {
        +String id
        +String postId
        +String userId
        +Timestamp createdAt
    }
    
    class Chatrooms {
        +String id
        +List~String~ participantIds
        +String? groupName
        +String? groupImage
        +bool isGroup
        +Timestamp lastMessageTime
        +String lastMessageText
        +String lastMessageSenderId
        +Map~String, Timestamp~ readStatus
    }
    
    class Messages {
        +String id
        +String chatId
        +String senderId
        +String? senderName
        +String? senderAvatar
        +String content
        +String type
        +String? mediaUrl
        +List~String~ seenBy
        +Timestamp createdAt
    }
    
    class Friendships {
        +String friendshipId
        +String senderId
        +String receiverId
        +bool isAccepted
        +Timestamp createdAt
    }
    
    class Notifications {
        +String id
        +String senderId
        +String receiverId
        +String content
        +String type
        +String? postId
        +String? commentId
        +String? chatId
        +bool isRead
        +Timestamp createdAt
        +String? senderName
        +String? senderAvatar
    }

    Users "1" --> "0..*" Posts : creates
    Users "1" --> "0..*" Comments : writes
    Users "1" --> "0..*" Likes : gives
    Users "1" --> "0..*" Messages : sends
    Users "1" --> "0..*" Friendships : has
    Users "1" --> "0..*" Notifications : receives
    Posts "1" --> "0..*" Comments : has
    Posts "1" --> "0..*" Likes : has
    Chatrooms "1" --> "0..*" Messages : contains
``` 