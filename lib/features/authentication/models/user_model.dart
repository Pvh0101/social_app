import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

import '../../../core/utils/datetime_helper.dart';

/// Model đại diện cho người dùng trong ứng dụng.
///
/// [UserModel] lưu trữ tất cả thông tin liên quan đến người dùng bao gồm
/// thông tin cá nhân, trạng thái trực tuyến, và các cài đặt riêng tư.
/// Model này được sử dụng trong toàn bộ ứng dụng để hiển thị thông tin người dùng
/// và quản lý phiên đăng nhập.
class UserModel extends Equatable {
  /// ID duy nhất của người dùng, thường là UID từ Firebase Auth
  final String uid;

  /// Token FCM để gửi thông báo đẩy
  final String? token;

  /// Địa chỉ email của người dùng
  final String email;

  /// Họ tên đầy đủ của người dùng
  final String fullName;

  /// Giới tính của người dùng (nam/nữ/khác)
  final String? gender;

  /// Ngày sinh của người dùng
  final DateTime? birthDay;

  /// Số điện thoại của người dùng
  final String? phoneNumber;

  /// Địa chỉ của người dùng
  final String? address;

  /// URL ảnh đại diện của người dùng
  final String? profileImage;

  /// Mô tả ngắn về người dùng
  final String? decs;

  /// Thời điểm cuối cùng người dùng truy cập ứng dụng
  final DateTime? lastSeen;

  /// Thời điểm tài khoản được tạo
  final DateTime? createdAt;

  /// Trạng thái trực tuyến của người dùng
  final bool isOnline;

  /// Cài đặt tài khoản riêng tư (true = chỉ bạn bè mới xem được thông tin)
  final bool isPrivateAccount;

  /// Số lượng người theo dõi
  final int followersCount;

  /// Constructor tạo đối tượng UserModel với các tham số bắt buộc và tùy chọn
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

  /// Kiểm tra profile đã hoàn thành chưa dựa trên các trường bắt buộc
  ///
  /// Trả về true nếu người dùng đã điền đầy đủ thông tin cần thiết
  bool get isProfileComplete {
    return fullName.trim().isNotEmpty &&
        (phoneNumber?.isNotEmpty ?? false) &&
        birthDay != null &&
        gender != null;
  }

  /// Tạo đối tượng UserModel từ Map dữ liệu
  ///
  /// Thường được sử dụng khi lấy dữ liệu từ Firestore
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

  /// Chuyển đổi đối tượng UserModel thành Map dữ liệu
  ///
  /// Thường được sử dụng khi lưu dữ liệu vào Firestore
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

  /// Tạo bản sao của đối tượng UserModel với một số thuộc tính được thay đổi
  ///
  /// Phương thức này giúp tạo đối tượng mới mà không thay đổi đối tượng gốc (immutability)
  UserModel copyWith({
    String? uid,
    String? token,
    String? email,
    String? fullName,
    String? gender,
    DateTime? birthDay,
    String? phoneNumber,
    String? address,
    String? profileImage,
    String? decs,
    DateTime? lastSeen,
    DateTime? createdAt,
    bool? isOnline,
    bool? isPrivateAccount,
    int? followersCount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      token: token ?? this.token,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      birthDay: birthDay ?? this.birthDay,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      decs: decs ?? this.decs,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      isOnline: isOnline ?? this.isOnline,
      isPrivateAccount: isPrivateAccount ?? this.isPrivateAccount,
      followersCount: followersCount ?? this.followersCount,
    );
  }

  /// Tạo đối tượng UserModel từ DocumentSnapshot của Firestore
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  /// Lấy văn bản hiển thị trạng thái hoạt động của người dùng
  ///
  /// Trả về "Đang hoạt động" nếu người dùng đang online,
  /// hoặc thời gian hoạt động cuối cùng nếu offline
  String get lastSeenText {
    if (isOnline) return 'datetime.online'.tr();
    if (lastSeen == null) return 'datetime.offline'.tr();
    return DateTimeHelper.getLastSeen(lastSeen);
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        isProfileComplete,
        lastSeen,
        createdAt,
        isOnline,
        isPrivateAccount,
        followersCount,
      ];
}
