# PHỤ LỤC CHỨC NĂNG CHI TIẾT

## PHỤ LỤC 5. CHỨC NĂNG QUẢN LÝ THÔNG TIN CÁ NHÂN

```dart
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  // Cập nhật thông tin cá nhân
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    File? newAvatar,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (bio != null) updates['bio'] = bio;

      if (newAvatar != null) {
        final avatarUrl = await _storage.uploadFile(
          'avatars/$userId',
          newAvatar,
        );
        updates['avatar'] = avatarUrl;
      }

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Cập nhật thông tin thất bại: $e');
    }
  }

  // Lấy thông tin người dùng
  Stream<UserModel> getUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromDocument(doc));
  }
}
```

## PHỤ LỤC 6. CHỨC NĂNG QUẢN LÝ BÀI VIẾT

```dart
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  // Thêm bài viết mới
  Future<void> createPost({
    required String userId,
    required String content,
    List<File>? media,
  }) async {
    try {
      final postId = const Uuid().v4();
      final mediaUrls = <String>[];

      if (media != null) {
        for (var file in media) {
          final url = await _storage.uploadFile(
            'posts/$postId/${DateTime.now().millisecondsSinceEpoch}',
            file,
          );
          mediaUrls.add(url);
        }
      }

      final post = Post(
        id: postId,
        userId: userId,
        content: content,
        mediaUrls: mediaUrls,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('posts').doc(postId).set(post.toMap());
    } catch (e) {
      throw Exception('Tạo bài viết thất bại: $e');
    }
  }

  // Cập nhật bài viết
  Future<void> updatePost({
    required String postId,
    required String content,
  }) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Cập nhật bài viết thất bại: $e');
    }
  }

  // Xóa bài viết
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Xóa bài viết thất bại: $e');
    }
  }
}
```

## PHỤ LỤC 7. CHỨC NĂNG QUẢN LÝ THÔNG BÁO

```dart
enum NotificationType {
  like('like'),
  comment('comment'),
  mention('mention'),
  friendRequest('friend_request'),
  friendAccept('friend_accept'),
  message('message');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (element) => element.value == value,
      orElse: () => NotificationType.message,
    );
  }

  String getTemplateMessage(String senderName) {
    switch (this) {
      case NotificationType.like:
        return '$senderName đã thích bài viết của bạn';
      case NotificationType.comment:
        return '$senderName đã bình luận về bài viết của bạn';
      case NotificationType.mention:
        return '$senderName đã nhắc đến bạn trong một bài viết';
      case NotificationType.friendRequest:
        return '$senderName đã gửi lời mời kết bạn';
      case NotificationType.friendAccept:
        return '$senderName đã chấp nhận lời mời kết bạn của bạn';
      case NotificationType.message:
        return '$senderName đã gửi tin nhắn cho bạn';
    }
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId;

  NotificationService(this._currentUserId);

  // Lấy danh sách thông báo
  Stream<List<NotificationModel>> getNotifications() {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Đánh dấu thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
```

## PHỤ LỤC 8. CHỨC NĂNG QUẢN LÝ BẠN BÈ

```dart
class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notification;

  FriendService(this._notification);

  // Gửi lời mời kết bạn
  Future<void> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final friendshipId = _createFriendshipId(senderId, receiverId);
      
      await _firestore.collection('friendships').doc(friendshipId).set({
        'senderId': senderId,
        'receiverId': receiverId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Gửi thông báo
      await _notification.createFriendRequestNotification(
        senderId: senderId,
        receiverId: receiverId,
      );
    } catch (e) {
      throw Exception('Gửi lời mời kết bạn thất bại: $e');
    }
  }

  // Chấp nhận lời mời kết bạn
  Future<void> acceptFriendRequest({
    required String userId,
    required String friendId,
  }) async {
    try {
      final friendshipId = _createFriendshipId(userId, friendId);

      await _firestore.collection('friendships').doc(friendshipId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Gửi thông báo
      await _notification.createFriendAcceptNotification(
        senderId: userId,
        receiverId: friendId,
      );
    } catch (e) {
      throw Exception('Chấp nhận lời mời kết bạn thất bại: $e');
    }
  }
}
```

## PHỤ LỤC 9. CHỨC NĂNG QUẢN LÝ NHÓM CHAT

```dart
class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId;

  GroupChatService(this._currentUserId);

  // Tạo nhóm chat mới
  Future<void> createGroup({
    required String name,
    required List<String> members,
    String? avatar,
  }) async {
    try {
      final groupId = const Uuid().v4();
      final allMembers = [...members, _currentUserId];

      await _firestore.collection('chats').doc(groupId).set({
        'id': groupId,
        'name': name,
        'avatar': avatar,
        'isGroup': true,
        'members': allMembers,
        'admins': [_currentUserId],
        'createdBy': _currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Không thể tạo nhóm chat: $e');
    }
  }

  // Thêm thành viên vào nhóm
  Future<void> addMember(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'members': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Không thể thêm thành viên: $e');
    }
  }

  // Xóa thành viên khỏi nhóm
  Future<void> removeMember(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'members': FieldValue.arrayRemove([userId]),
        'admins': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw Exception('Không thể xóa thành viên: $e');
    }
  }

  // Rời nhóm
  Future<void> leaveGroup(String chatId) async {
    try {
      await removeMember(chatId, _currentUserId);
    } catch (e) {
      throw Exception('Không thể rời nhóm: $e');
    }
  }
}
```

## PHỤ LỤC 11. CHỨC NĂNG QUẢN LÝ BÌNH LUẬN

```dart
class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notification;

  CommentService(this._notification);

  // Thêm bình luận mới
  Future<void> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentId,
  }) async {
    try {
      final commentId = const Uuid().v4();
      
      await _firestore.collection('comments').doc(commentId).set({
        'id': commentId,
        'postId': postId,
        'userId': userId,
        'content': content,
        'parentId': parentId,
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật số lượng bình luận của bài viết
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Gửi thông báo cho chủ bài viết
      await _notification.createCommentNotification(
        postId: postId,
        commentId: commentId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Thêm bình luận thất bại: $e');
    }
  }

  // Xóa bình luận
  Future<void> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();

      // Cập nhật số lượng bình luận của bài viết
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Xóa bình luận thất bại: $e');
    }
  }

  // Lấy danh sách bình luận của bài viết
  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromMap(doc.data())).toList();
    });
  }
}
```

## PHỤ LỤC 12. CHỨC NĂNG QUẢN LÝ LIKE

```dart
class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notification;

  LikeService(this._notification);

  // Thêm/xóa like
  Future<void> toggleLike({
    required String contentId,
    required String contentType,
    required String userId,
  }) async {
    try {
      final likeId = _createLikeId(contentId, userId);
      final likeRef = _firestore.collection('likes').doc(likeId);
      final contentRef = _firestore.collection(contentType).doc(contentId);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
        await contentRef.update({
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likeRef.set({
          'id': likeId,
          'contentId': contentId,
          'contentType': contentType,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await contentRef.update({
          'likeCount': FieldValue.increment(1),
        });

        // Gửi thông báo cho chủ nội dung
        await _notification.createLikeNotification(
          contentId: contentId,
          contentType: contentType,
          userId: userId,
        );
      }
    } catch (e) {
      throw Exception('Không thể thực hiện thao tác like: $e');
    }
  }

  // Kiểm tra người dùng đã like nội dung chưa
  Future<bool> hasLiked({
    required String contentId,
    required String userId,
  }) async {
    try {
      final likeId = _createLikeId(contentId, userId);
      final doc = await _firestore.collection('likes').doc(likeId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Không thể kiểm tra trạng thái like: $e');
    }
  }

  // Lấy danh sách người dùng đã like nội dung
  Stream<List<UserModel>> getLikedUsers(String contentId) {
    return _firestore
        .collection('likes')
        .where('contentId', isEqualTo: contentId)
        .snapshots()
        .asyncMap((snapshot) async {
      final userIds = snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
      
      if (userIds.isEmpty) return [];

      final userDocs = await _firestore
          .collection('users')
          .where('id', whereIn: userIds)
          .get();

      return userDocs.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  String _createLikeId(String contentId, String userId) {
    return '$contentId-$userId';
  }
}
```

## PHỤ LỤC 13. CHỨC NĂNG QUẢN LÝ MEDIA

```dart
class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _currentUserId;

  MediaService(this._currentUserId);

  // Upload file lên storage
  Future<String> uploadFile(String path, File file) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Upload file thất bại: $e');
    }
  }

  // Upload nhiều file
  Future<List<String>> uploadFiles(String path, List<File> files) async {
    try {
      final urls = <String>[];
      for (var file in files) {
        final url = await uploadFile(
          '$path/${DateTime.now().millisecondsSinceEpoch}',
          file,
        );
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception('Upload files thất bại: $e');
    }
  }

  // Xóa file từ storage
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Xóa file thất bại: $e');
    }
  }

  // Xóa nhiều file
  Future<void> deleteFiles(List<String> urls) async {
    try {
      for (var url in urls) {
        await deleteFile(url);
      }
    } catch (e) {
      throw Exception('Xóa files thất bại: $e');
    }
  }
}
```

## PHỤ LỤC 16. CHỨC NĂNG THÔNG BÁO

```dart
enum NotificationType {
  like('like'),
  comment('comment'),
  mention('mention'),
  friendRequest('friend_request'),
  friendAccept('friend_accept'),
  message('message');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (element) => element.value == value,
      orElse: () => NotificationType.message,
    );
  }

  String getTemplateMessage(String senderName) {
    switch (this) {
      case NotificationType.like:
        return '$senderName đã thích bài viết của bạn';
      case NotificationType.comment:
        return '$senderName đã bình luận về bài viết của bạn';
      case NotificationType.mention:
        return '$senderName đã nhắc đến bạn trong một bài viết';
      case NotificationType.friendRequest:
        return '$senderName đã gửi lời mời kết bạn';
      case NotificationType.friendAccept:
        return '$senderName đã chấp nhận lời mời kết bạn của bạn';
      case NotificationType.message:
        return '$senderName đã gửi tin nhắn cho bạn';
    }
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId;

  NotificationService(this._currentUserId);

  // Lấy danh sách thông báo
  Stream<List<NotificationModel>> getNotifications() {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Đánh dấu thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
```

## PHỤ LỤC 17. CHỨC NĂNG QUẢN LÝ THÔNG TIN CÁ NHÂN

```dart
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  // Cập nhật thông tin cá nhân
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    File? newAvatar,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (bio != null) updates['bio'] = bio;

      if (newAvatar != null) {
        final avatarUrl = await _storage.uploadFile(
          'avatars/$userId',
          newAvatar,
        );
        updates['avatar'] = avatarUrl;
      }

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Cập nhật thông tin thất bại: $e');
    }
  }

  // Lấy thông tin người dùng
  Stream<UserModel> getUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromDocument(doc));
  }
}
```

## PHỤ LỤC 18. CHỨC NĂNG QUẢN LÝ BÀI VIẾT

```dart
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  // Thêm bài viết mới
  Future<void> createPost({
    required String userId,
    required String content,
    List<File>? media,
  }) async {
    try {
      final postId = const Uuid().v4();
      final mediaUrls = <String>[];

      if (media != null) {
        for (var file in media) {
          final url = await _storage.uploadFile(
            'posts/$postId/${DateTime.now().millisecondsSinceEpoch}',
            file,
          );
          mediaUrls.add(url);
        }
      }

      final post = Post(
        id: postId,
        userId: userId,
        content: content,
        mediaUrls: mediaUrls,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('posts').doc(postId).set(post.toMap());
    } catch (e) {
      throw Exception('Tạo bài viết thất bại: $e');
    }
  }

  // Cập nhật bài viết
  Future<void> updatePost({
    required String postId,
    required String content,
  }) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Cập nhật bài viết thất bại: $e');
    }
  }

  // Xóa bài viết
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Xóa bài viết thất bại: $e');
    }
  }
}
```

## PHỤ LỤC 26. CHỨC NĂNG CHAT REPOSITORY

```dart
class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId;

  ChatRepository(this._currentUserId);

  // Lấy danh sách chat của người dùng
  Stream<List<Chatroom>> getUserChats() {
    return _firestore
        .collection('chats')
        .where('members', arrayContains: _currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Chatroom.fromMap(doc.data())).toList();
    });
  }

  // Lấy thông tin chi tiết của một chat
  Stream<Chatroom> getChatDetails(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) => Chatroom.fromMap(doc.data()!));
  }

  // Gửi tin nhắn
  Future<void> sendMessage({
    required String chatId,
    required String content,
    required MessageType type,
    String? mediaUrl,
  }) async {
    try {
      final message = Message(
        id: const Uuid().v4(),
        chatId: chatId,
        senderId: _currentUserId,
        content: content,
        type: type,
        mediaUrl: mediaUrl,
        seenBy: {_currentUserId},
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());

      // Cập nhật thông tin chat
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastMessageType': type.name,
        'lastMessageSenderId': _currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gửi tin nhắn thất bại: $e');
    }
  }

  // Đánh dấu tin nhắn đã đọc
  Future<void> markMessageAsSeen(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'seenBy': FieldValue.arrayUnion([_currentUserId]),
      });
    } catch (e) {
      throw Exception('Không thể đánh dấu tin nhắn đã đọc: $e');
    }
  }
}
```

## PHỤ LỤC 27. MESSAGE TYPE ENUM

```dart
enum MessageType {
  text,
  image,
  video,
  audio;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MessageType.text,
    );
  }

  String get displayText {
    switch (this) {
      case MessageType.text:
        return 'chat.message_type.text'.tr();
      case MessageType.image:
        return 'chat.message_type.image'.tr();
      case MessageType.video:
        return 'chat.message_type.video'.tr();
      case MessageType.audio:
        return 'chat.message_type.audio'.tr();
    }
  }
}
``` 