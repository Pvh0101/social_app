# PHỤ LỤC CHỨC NĂNG CHI TIẾT

## PHỤ LỤC 14. CHỨC NĂNG ĐĂNG KÝ VÀ ĐĂNG NHẬP

```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng ký tài khoản mới
  Future<UserCredential> register({
    required String email,
    required String password,
    required String fullName,
    File? avatar,
  }) async {
    try {
      // Tạo tài khoản Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? avatarUrl;
      if (avatar != null) {
        // Upload avatar nếu có
        avatarUrl = await StorageService().uploadFile(
          'avatars/${userCredential.user!.uid}',
          avatar,
        );
      }

      // Tạo document user trong Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'fullName': fullName,
        'avatar': avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  // Đăng nhập
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật trạng thái online
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }
}
```

## PHỤ LỤC 15. CHỨC NĂNG NHẮN TIN

```dart
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId;

  ChatService(this._currentUserId);

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

  // Lấy danh sách tin nhắn
  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
    });
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

      await _firestore.collection('posts').doc(postId).set({
        'userId': userId,
        'content': content,
        'media': mediaUrls,
        'likes': [],
        'comments': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Tạo bài viết thất bại: $e');
    }
  }

  // Chỉnh sửa bài viết
  Future<void> updatePost({
    required String postId,
    String? content,
    List<String>? mediaToRemove,
    List<File>? mediaToAdd,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (content != null) updates['content'] = content;

      if (mediaToAdd != null) {
        final newMediaUrls = <String>[];
        for (var file in mediaToAdd) {
          final url = await _storage.uploadFile(
            'posts/$postId/${DateTime.now().millisecondsSinceEpoch}',
            file,
          );
          newMediaUrls.add(url);
        }

        // Cập nhật danh sách media
        if (mediaToRemove != null) {
          await _firestore.collection('posts').doc(postId).get().then((doc) {
            final currentMedia = List<String>.from(doc.data()?['media'] ?? []);
            currentMedia.removeWhere((url) => mediaToRemove.contains(url));
            currentMedia.addAll(newMediaUrls);
            updates['media'] = currentMedia;
          });
        }
      }

      await _firestore.collection('posts').doc(postId).update(updates);
    } catch (e) {
      throw Exception('Cập nhật bài viết thất bại: $e');
    }
  }

  // Xóa bài viết
  Future<void> deletePost(String postId) async {
    try {
      // Xóa media từ storage
      final doc = await _firestore.collection('posts').doc(postId).get();
      final media = List<String>.from(doc.data()?['media'] ?? []);
      for (var url in media) {
        await _storage.deleteFile(url);
      }

      // Xóa document từ Firestore
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Xóa bài viết thất bại: $e');
    }
  }
}
```

## PHỤ LỤC 19. CHỨC NĂNG QUẢN LÝ BẠN BÈ

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

  // Xóa bạn bè
  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      final friendshipId = _createFriendshipId(userId, friendId);
      await _firestore.collection('friendships').doc(friendshipId).delete();
    } catch (e) {
      throw Exception('Xóa bạn bè thất bại: $e');
    }
  }

  String _createFriendshipId(String userIdA, String userIdB) {
    final ids = [userIdA, userIdB]..sort();
    return 'friendship_${ids[0]}_${ids[1]}';
  }
}
```

## PHỤ LỤC 20. CHỨC NĂNG QUẢN LÝ NHÓM CHAT

```dart
class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  // Tạo nhóm chat mới
  Future<String> createGroup({
    required String name,
    required String creatorId,
    required List<String> memberIds,
    File? avatar,
  }) async {
    try {
      final groupId = const Uuid().v4();
      String? avatarUrl;

      if (avatar != null) {
        avatarUrl = await _storage.uploadFile(
          'groups/$groupId/avatar',
          avatar,
        );
      }

      final group = Chatroom(
        id: groupId,
        name: name,
        avatar: avatarUrl,
        isGroup: true,
        isPublic: false,
        members: [creatorId, ...memberIds],
        admins: [creatorId],
        createdBy: creatorId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('chats').doc(groupId).set(group.toMap());
      return groupId;
    } catch (e) {
      throw Exception('Tạo nhóm chat thất bại: $e');
    }
  }

  // Cập nhật thông tin nhóm
  Future<void> updateGroup({
    required String groupId,
    String? name,
    File? newAvatar,
    List<String>? newMembers,
    List<String>? newAdmins,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (newMembers != null) updates['members'] = newMembers;
      if (newAdmins != null) updates['admins'] = newAdmins;

      if (newAvatar != null) {
        final avatarUrl = await _storage.uploadFile(
          'groups/$groupId/avatar',
          newAvatar,
        );
        updates['avatar'] = avatarUrl;
      }

      await _firestore.collection('chats').doc(groupId).update(updates);
    } catch (e) {
      throw Exception('Cập nhật nhóm chat thất bại: $e');
    }
  }

  // Xóa nhóm chat
  Future<void> deleteGroup(String groupId) async {
    try {
      // Xóa avatar từ storage nếu có
      final doc = await _firestore.collection('chats').doc(groupId).get();
      final avatarUrl = doc.data()?['avatar'];
      if (avatarUrl != null) {
        await _storage.deleteFile(avatarUrl);
      }

      // Xóa tất cả tin nhắn trong nhóm
      final messages = await _firestore
          .collection('chats')
          .doc(groupId)
          .collection('messages')
          .get();
      
      for (var message in messages.docs) {
        await message.reference.delete();
      }

      // Xóa nhóm
      await _firestore.collection('chats').doc(groupId).delete();
    } catch (e) {
      throw Exception('Xóa nhóm chat thất bại: $e');
    }
  }
}
```

## PHỤ LỤC 21. USER MODEL

```dart
class UserModel extends Equatable {
  final String uid;
  final String? token;
  final String email;
  final String fullName;
  final String? gender;
  final DateTime? birthDay;
  final String? phoneNumber;
  final String? address;
  final String? profileImage;
  final String? decs;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final bool isOnline;
  final bool isPrivateAccount;
  final int followersCount;

  const UserModel({
    required this.uid,
    this.token,
    required this.email,
    required this.fullName,
    this.gender,
    this.birthDay,
    this.phoneNumber,
    this.address,
    this.profileImage,
    this.decs,
    this.lastSeen,
    this.createdAt,
    this.isOnline = false,
    this.isPrivateAccount = false,
    this.followersCount = 0,
  });

  bool get isProfileComplete {
    return fullName.trim().isNotEmpty &&
        (phoneNumber?.isNotEmpty ?? false) &&
        birthDay != null &&
        gender != null;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      token: map['token'] as String?,
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      gender: map['gender'] as String?,
      birthDay: DateTimeHelper.fromMap(map['birthDay']),
      phoneNumber: map['phoneNumber'] as String?,
      address: map['address'] as String?,
      profileImage: map['profileImage'] as String?,
      decs: map['decs'] as String?,
      lastSeen: DateTimeHelper.fromMap(map['lastSeen']),
      createdAt: DateTimeHelper.fromMap(map['createdAt']),
      isOnline: map['isOnline'] as bool? ?? false,
      isPrivateAccount: map['isPrivateAccount'] as bool? ?? false,
      followersCount: map['followersCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'token': token,
      'email': email,
      'fullName': fullName,
      'gender': gender,
      'birthDay': DateTimeHelper.toMap(birthDay),
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImage': profileImage,
      'decs': decs,
      'lastSeen': DateTimeHelper.toMap(lastSeen),
      'createdAt': DateTimeHelper.toMap(createdAt),
      'isOnline': isOnline,
      'isPrivateAccount': isPrivateAccount,
      'followersCount': followersCount,
    };
  }
}
```

## PHỤ LỤC 22. AUTHENTICATION REPOSITORY

```dart
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FCMService _fcmService;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    required FCMService fcmService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _fcmService = fcmService;

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'isOnline': false,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      await credential.user!.sendEmailVerification();
      return credential;
    } catch (e) {
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Không tìm thấy người dùng');
      }
      return user.emailVerified;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Không tìm thấy người dùng');
      }
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel> updateUserProfile({
    required String uid,
    required String fullName,
    required String gender,
    required DateTime birthDay,
    required String phoneNumber,
    String? address,
    String? desc,
    File? profileImage,
  }) async {
    try {
      String? imageUrl;
      if (profileImage != null) {
        imageUrl = await uploadFileToFirebase(
          file: profileImage,
          reference: 'profile_pics/$uid',
        );
      }

      final currentUserDoc = await _firestore.collection('users').doc(uid).get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final currentToken = currentUserData['token'] as String?;

      final userModel = UserModel(
        uid: uid,
        email: _auth.currentUser!.email!,
        fullName: fullName,
        gender: gender,
        birthDay: birthDay,
        phoneNumber: phoneNumber,
        address: address,
        decs: desc,
        profileImage: imageUrl ?? currentUserData['profileImage'],
        createdAt: DateTimeHelper.fromMap(currentUserData['createdAt']) ??
            DateTime.now(),
        isOnline: true,
        token: currentToken,
        lastSeen: DateTimeHelper.fromMap(currentUserData['lastSeen']) ??
            DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(
            userModel.toMap(),
            SetOptions(merge: true),
          );

      return userModel;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updateUserStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final updates = <String, dynamic>{
        'isOnline': isOnline,
      };

      if (!isOnline) {
        updates['lastSeen'] = DateTimeHelper.toMap(DateTime.now());
      }

      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      throw Exception('Không thể cập nhật trạng thái: ${e.toString()}');
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await updateUserStatus(true);
      await _fcmService.saveTokenToUser(credential.user!.uid);

      return credential;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }
}
```

## PHỤ LỤC 23. AUTHENTICATION PROVIDERS

```dart
// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final fcmService = ref.watch(fcmServiceProvider);
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    fcmService: fcmService,
  );
});

// Auth State Provider
final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Get User Info Provider
final getUserInfoProvider = FutureProvider.autoDispose<UserModel>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .get()
      .then((userData) {
    return UserModel.fromMap(userData.data()!);
  });
});

// Get User Info As Stream Provider
final getUserInfoAsStreamProvider =
    StreamProvider.autoDispose<UserModel>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    final userData = snapshot.docs.first;
    return UserModel.fromMap(userData.data());
  });
});

// Get User Info By Id Provider
final getUserInfoByIdProvider =
    FutureProvider.autoDispose.family<UserModel, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get()
      .then((userData) {
    return UserModel.fromMap(userData.data()!);
  });
});

// Get User Info As Stream By Id Provider
final getUserInfoAsStreamByIdProvider =
    StreamProvider.autoDispose.family<UserModel, String>((ref, String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('uid', isEqualTo: userId)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    final userData = snapshot.docs.first;
    return UserModel.fromMap(userData.data());
  });
});
```

## PHỤ LỤC 24. MESSAGE MODEL

```dart
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final String? mediaUrl;
  final Set<String> seenBy;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.seenBy,
    required this.createdAt,
  });

  bool isSeenBy(String userId) => seenBy.contains(userId);

  String getDisplayContent() {
    if (type == MessageType.text) {
      return content;
    }
    return 'chat.message.sent_media'.tr(args: [type.displayText.toLowerCase()]);
  }

  String get createdAtText => DateTimeHelper.getRelativeTime(createdAt);

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'],
      senderAvatar: map['senderAvatar'],
      content: map['content'] ?? '',
      type: MessageType.fromString(map['type'] ?? ''),
      mediaUrl: map['mediaUrl'],
      seenBy: Set<String>.from(map['seenBy'] ?? []),
      createdAt: DateTimeHelper.fromMap(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'seenBy': seenBy.toList(),
      'createdAt': DateTimeHelper.toMap(createdAt),
    };
  }
}
```

## PHỤ LỤC 25. CHATROOM MODEL

```dart
class Chatroom {
  final String id;
  final String? name;
  final String? avatar;
  final bool isGroup;
  final bool isPublic;
  final List<String> members;
  final List<String> admins;
  final String? lastMessageId;
  final String? lastMessage;
  final MessageType? lastMessageType;
  final String? lastMessageSenderId;
  final DateTime updatedAt;
  final String createdBy;
  final DateTime createdAt;

  Chatroom({
    required this.id,
    this.name,
    this.avatar,
    required this.isGroup,
    required this.isPublic,
    required this.members,
    required this.admins,
    this.lastMessageId,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageSenderId,
    required this.updatedAt,
    required this.createdBy,
    required this.createdAt,
  });

  bool isAdmin(String userId) => admins.contains(userId);
  bool isMember(String userId) => members.contains(userId);
  bool canJoin(String userId) => isPublic || isAdmin(userId);

  factory Chatroom.fromMap(Map<String, dynamic> map) {
    return Chatroom(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      avatar: map['avatar'],
      isGroup: map['isGroup'] ?? false,
      isPublic: map['isPublic'] ?? false,
      members: List<String>.from(map['members'] ?? []),
      admins: List<String>.from(map['admins'] ?? []),
      lastMessageId: map['lastMessageId'],
      lastMessage: map['lastMessage'],
      lastMessageType: map['lastMessageType'] != null
          ? MessageType.fromString(map['lastMessageType'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      updatedAt: DateTimeHelper.fromMap(map['updatedAt']) ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTimeHelper.fromMap(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'isGroup': isGroup,
      'isPublic': isPublic,
      'members': members,
      'admins': admins,
      'lastMessageId': lastMessageId,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType?.name,
      'lastMessageSenderId': lastMessageSenderId,
      'updatedAt': DateTimeHelper.toMap(updatedAt),
      'createdBy': createdBy,
      'createdAt': DateTimeHelper.toMap(createdAt),
    };
  }
}
```

## PHỤ LỤC 26. CHAT REPOSITORY

```dart
class ChatRepository {
  final FirebaseFirestore _firestore;
  final String _currentUserId;
  final NotificationRepository _notificationRepository;

  ChatRepository({
    required FirebaseFirestore firestore,
    required String currentUserId,
  })  : _firestore = firestore,
        _currentUserId = currentUserId,
        _notificationRepository = NotificationRepository();

  // Lấy danh sách chat của người dùng
  Stream<List<Chatroom>> getUserChats() {
    return _firestore
        .collection('chats')
        .where('members', arrayContains: _currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Chatroom.fromMap(doc.data())).toList();
    });
  }

  // Lấy thông tin chi tiết của một chat
  Future<Chatroom?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;
      return Chatroom.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Không thể lấy thông tin chat: $e');
    }
  }

  // Lấy danh sách tin nhắn của một chat
  Stream<List<Message>> getChatMessages(String chatId, {int limit = 100}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
    });
  }

  // Gửi tin nhắn văn bản
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

      // Gửi thông báo cho các thành viên khác
      final chat = await getChatById(chatId);
      if (chat != null) {
        for (final memberId in chat.members) {
          if (memberId != _currentUserId) {
            await _notificationRepository.createMessageNotification(
              senderId: _currentUserId,
              receiverId: memberId,
              chatId: chatId,
              message: content,
            );
          }
        }
      }
    } catch (e) {
      throw Exception('Gửi tin nhắn thất bại: $e');
    }
  }

  // Gửi tin nhắn media
  Future<void> sendMediaMessage({
    required String chatId,
    required File file,
    required MessageType type,
  }) async {
    try {
      final mediaUrl = await uploadFileToFirebase(
        file: file,
        reference: 'chats/$chatId/media/${DateTime.now().millisecondsSinceEpoch}',
      );

      await sendMessage(
        chatId: chatId,
        content: 'Đã gửi ${type.displayText.toLowerCase()}',
        type: type,
        mediaUrl: mediaUrl,
      );
    } catch (e) {
      throw Exception('Gửi media thất bại: $e');
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
        'seenBy': FieldValue.arrayUnion([_currentUserId])
      });
    } catch (e) {
      throw Exception('Không thể đánh dấu tin nhắn đã đọc: $e');
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

## PHỤ LỤC 28. CHAT PROVIDERS

```dart
// Provider cho danh sách chat của người dùng
final userChatsProvider = StreamProvider<List<Chatroom>>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getUserChats();
});

// Provider cho thông tin chi tiết của một chat
final chatProvider =
    FutureProvider.family<Chatroom?, String>((ref, chatId) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getChatById(chatId);
});

// Provider cho danh sách tin nhắn của một chat
final chatMessagesProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getChatMessages(chatId, limit: 100);
});

// Provider cho việc gửi tin nhắn
final sendMessageProvider =
    FutureProvider.family<void, SendMessageParams>((ref, params) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  await chatRepository.sendMessage(
    chatId: params.chatId,
    content: params.content,
    type: params.type,
    mediaUrl: params.mediaUrl,
  );
});

// Provider cho việc gửi tin nhắn media
final sendMediaMessageProvider =
    FutureProvider.family<void, SendMediaParams>((ref, params) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  await chatRepository.sendMediaMessage(
    chatId: params.chatId,
    file: params.file,
    type: params.type,
  );
});

// Provider cho việc đánh dấu tin nhắn đã đọc
final markMessageAsSeenProvider =
    FutureProvider.family<void, MarkMessageParams>((ref, params) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  await chatRepository.markMessageAsSeen(params.chatId, params.messageId);
});
``` 