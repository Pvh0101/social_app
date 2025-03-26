import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../core/utils/datetime_helper.dart';

class FriendshipModel extends Equatable {
  final String friendshipId;
  final String senderId;
  final String receiverId;
  final bool isAccepted;
  final DateTime createdAt;

  const FriendshipModel({
    required this.friendshipId,
    required this.senderId,
    required this.receiverId,
    required this.isAccepted,
    required this.createdAt,
  });

  factory FriendshipModel.fromMap(Map<String, dynamic> map) {
    return FriendshipModel(
      friendshipId: map['friendshipId'] as String,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      isAccepted: map['isAccepted'] as bool,
      createdAt: DateTimeHelper.fromMap(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'friendshipId': friendshipId,
      'senderId': senderId,
      'receiverId': receiverId,
      'isAccepted': isAccepted,
      'createdAt': DateTimeHelper.toMap(createdAt),
    };
  }

  factory FriendshipModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendshipModel.fromMap(data);
  }

  FriendshipModel copyWith({
    String? friendshipId,
    String? senderId,
    String? receiverId,
    bool? isAccepted,
    DateTime? createdAt,
  }) {
    return FriendshipModel(
      friendshipId: friendshipId ?? this.friendshipId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      isAccepted: isAccepted ?? this.isAccepted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Lấy thời gian kết bạn dưới dạng relative time
  String get createdAtText => DateTimeHelper.getRelativeTime(createdAt);

  @override
  List<Object?> get props => [
        friendshipId,
        senderId,
        receiverId,
        isAccepted,
        createdAt,
      ];
}
