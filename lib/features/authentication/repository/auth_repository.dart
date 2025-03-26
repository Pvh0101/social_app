import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/firebase_constants.dart';
import '../models/user_model.dart';
import '../../../core/utils/log_utils.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/utils/datetime_helper.dart';
import '../../../core/services/media/media_service.dart';

/// Repository xử lý các thao tác xác thực và quản lý tài khoản người dùng.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FCMService _fcmService;
  final MediaService _mediaService = MediaService();

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    required FCMService fcmService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _fcmService = fcmService {
    logDebug(LogService.AUTH, '[INIT] AuthRepository được khởi tạo');
  }

  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  /// Tạo tài khoản mới với email và mật khẩu.
  ///
  /// Throws [Exception] nếu:
  /// - Email đã được sử dụng
  /// - Mật khẩu không đủ mạnh
  /// - Không có kết nối mạng
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      logInfo(LogService.AUTH, '[REGISTER] Bắt đầu tạo tài khoản: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Tạo document cơ bản trong Firestore
      await _users.doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'isOnline': false,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Gửi email xác thực không sử dụng ActionCodeSettings
      await credential.user!.sendEmailVerification();

      logInfo(LogService.AUTH, '[REGISTER] Đã gửi email xác thực đến $email');

      return credential;
    } on FirebaseAuthException catch (e) {
      logError(LogService.AUTH, '[REGISTER] Lỗi đăng ký: ${e.message}', e,
          StackTrace.current);
      throw Exception(e.message ?? 'Đăng ký thất bại');
    }
  }

  /// Kiểm tra trạng thái xác thực email của người dùng hiện tại.
  ///
  /// Returns `true` nếu email đã được xác thực.
  ///
  /// Throws [Exception] nếu không tìm thấy người dùng hoặc có lỗi xảy ra.
  Future<bool> checkEmailVerified() async {
    try {
      logDebug(LogService.AUTH, '[VERIFY] Kiểm tra xác thực email');

      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user == null) {
        logWarning(LogService.AUTH,
            '[VERIFY] Không tìm thấy người dùng để kiểm tra xác thực');
        throw Exception('Không tìm thấy người dùng');
      }

      final isVerified = user.emailVerified;

      if (isVerified) {
        logInfo(
            LogService.AUTH, '[VERIFY] Email ${user.email} đã được xác thực');
        return true;
      }

      logDebug(
          LogService.AUTH, '[VERIFY] Email ${user.email} chưa được xác thực');
      return isVerified;
    } catch (e) {
      logError(LogService.AUTH, '[VERIFY] Lỗi kiểm tra xác thực email', e,
          StackTrace.current);
      throw Exception(e.toString());
    }
  }

  /// Gửi lại email xác thực cho người dùng hiện tại.
  ///
  /// Throws [Exception] nếu không tìm thấy người dùng hoặc có lỗi xảy ra.
  Future<void> resendVerificationEmail() async {
    try {
      // Đảm bảo cập nhật thông tin người dùng từ server
      logDebug(LogService.AUTH, '[VERIFY] Bắt đầu gửi lại email xác thực');

      await _auth.currentUser?.reload();

      final user = _auth.currentUser;
      if (user == null) {
        logWarning(LogService.AUTH,
            '[VERIFY] Không tìm thấy người dùng để gửi email xác thực');
        throw Exception('Không tìm thấy người dùng');
      }

      // Kiểm tra nếu email đã được xác thực thì không cần gửi lại
      if (user.emailVerified) {
        logInfo(LogService.AUTH,
            '[VERIFY] Email đã được xác thực, không cần gửi lại');
        return;
      }

      // Gửi email xác thực không sử dụng ActionCodeSettings
      await user.sendEmailVerification();

      logInfo(
          LogService.AUTH, '[VERIFY] Đã gửi email xác thực đến ${user.email}');
    } catch (e) {
      logError(LogService.AUTH, '[VERIFY] Lỗi gửi lại email xác thực', e,
          StackTrace.current);
      throw Exception(e.toString());
    }
  }

  /// Cập nhật thông tin chi tiết của người dùng.
  ///
  /// Parameters:
  /// - [uid]: ID của người dùng
  /// - [fullName]: Họ tên đầy đủ
  /// - [gender]: Giới tính
  /// - [birthDay]: Ngày sinh
  /// - [phoneNumber]: Số điện thoại
  /// - [address]: Địa chỉ (tùy chọn)
  /// - [desc]: Mô tả (tùy chọn)
  /// - [profileImage]: Ảnh đại diện (tùy chọn)
  ///
  /// Returns [UserModel] chứa thông tin người dùng đã cập nhật.
  ///
  /// Throws [Exception] nếu có lỗi xảy ra trong quá trình cập nhật.
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
      logInfo(LogService.AUTH, '[PROFILE] Cập nhật thông tin người dùng: $uid');

      String? imageUrl;
      if (profileImage != null) {
        logDebug(LogService.AUTH,
            '[PROFILE] Bắt đầu tải lên ảnh đại diện cho người dùng: $uid');
        final uploadResult = await _mediaService.uploadSingleFile(
          file: profileImage,
          path: 'profile_pics/$uid',
        );

        if (uploadResult.isSuccess && uploadResult.downloadUrl != null) {
          imageUrl = uploadResult.downloadUrl;
          logInfo(LogService.AUTH,
              '[PROFILE] Tải lên ảnh đại diện thành công: $uid');
        } else {
          logWarning(LogService.AUTH,
              '[PROFILE] Tải lên ảnh đại diện không thành công: $uid');
        }
      }

      // Lấy thông tin user hiện tại để giữ nguyên token
      final currentUserDoc = await _users.doc(uid).get();
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

      await _users.doc(uid).set(userModel.toMap(), SetOptions(merge: true));
      logInfo(LogService.AUTH,
          '[PROFILE] Cập nhật thông tin người dùng thành công: $uid');

      return userModel;
    } catch (e) {
      logError(
          LogService.AUTH,
          '[PROFILE] Lỗi cập nhật thông tin người dùng: $uid',
          e,
          StackTrace.current);
      throw Exception(e.toString());
    }
  }

  /// Hoàn thiện thông tin profile cho tài khoản mới.
  ///
  /// Parameters:
  /// - [uid]: ID của người dùng
  /// - [fullName]: Họ tên đầy đủ
  /// - [gender]: Giới tính
  /// - [birthDay]: Ngày sinh
  /// - [phoneNumber]: Số điện thoại
  /// - [address]: Địa chỉ (tùy chọn)
  /// - [desc]: Mô tả (tùy chọn)
  /// - [profileImage]: Ảnh đại diện (tùy chọn)
  ///
  /// Returns [UserModel] chứa thông tin người dùng đã hoàn thiện.
  ///
  /// Throws [Exception] nếu có lỗi xảy ra trong quá trình hoàn thiện.
  Future<UserModel> completeUserProfile({
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
      logInfo(LogService.AUTH,
          '[PROFILE] Hoàn thiện thông tin người dùng mới: $uid');

      String? imageUrl;
      if (profileImage != null) {
        logDebug(LogService.AUTH,
            '[PROFILE] Bắt đầu tải lên ảnh đại diện cho người dùng mới: $uid');
        final uploadResult = await _mediaService.uploadSingleFile(
          file: profileImage,
          path: 'profile_pics/$uid',
        );

        if (uploadResult.isSuccess && uploadResult.downloadUrl != null) {
          imageUrl = uploadResult.downloadUrl;
          logInfo(LogService.AUTH,
              '[PROFILE] Tải lên ảnh đại diện thành công cho người dùng mới: $uid');
        } else {
          logWarning(LogService.AUTH,
              '[PROFILE] Tải lên ảnh đại diện không thành công cho người dùng mới: $uid');
        }
      }

      final userModel = UserModel(
        uid: uid,
        email: _auth.currentUser!.email!,
        fullName: fullName,
        gender: gender,
        birthDay: birthDay,
        phoneNumber: phoneNumber,
        address: address,
        decs: desc,
        profileImage: imageUrl,
        createdAt: DateTime.now(),
        isOnline: true,
        token: '', // Token sẽ được cập nhật sau
        lastSeen: DateTime.now(),
      );

      await _users.doc(uid).set(userModel.toMap());
      await _fcmService.saveTokenToUser(uid);

      logInfo(LogService.AUTH,
          '[PROFILE] Hoàn thiện thông tin người dùng mới thành công: $uid');
      return userModel;
    } catch (e) {
      logError(
          LogService.AUTH,
          '[PROFILE] Lỗi hoàn thiện thông tin người dùng mới: $uid',
          e,
          StackTrace.current);
      throw Exception(e.toString());
    }
  }

  /// Cập nhật trạng thái người dùng (online/offline)
  ///
  /// Parameters:
  /// - [isOnline]: Trạng thái mới của người dùng (true/false)
  ///
  /// Throws [Exception] nếu không thể cập nhật trạng thái
  Future<void> updateUserStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logWarning(LogService.AUTH,
            '[STATUS] Không thể cập nhật trạng thái: người dùng chưa đăng nhập');
        return;
      }

      logDebug(LogService.AUTH,
          '[STATUS] Cập nhật trạng thái người dùng: ${user.uid}, online: $isOnline');

      final updates = <String, dynamic>{
        'isOnline': isOnline,
      };

      // Chỉ cập nhật lastSeen khi chuyển sang offline
      if (!isOnline) {
        updates['lastSeen'] = DateTimeHelper.toMap(DateTime.now());
      }

      await _users.doc(user.uid).update(updates);
      logInfo(LogService.AUTH,
          '[STATUS] Đã cập nhật trạng thái người dùng: ${user.uid}, online: $isOnline');
    } catch (e) {
      logError(LogService.AUTH, '[STATUS] Lỗi cập nhật trạng thái người dùng',
          e, StackTrace.current);
      throw Exception('Không thể cập nhật trạng thái: ${e.toString()}');
    }
  }

  /// Đăng nhập với email và mật khẩu.
  ///
  /// Throws [Exception] nếu:
  /// - Email hoặc mật khẩu không chính xác
  /// - Tài khoản không tồn tại
  /// - Không có kết nối mạng
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      logInfo(LogService.AUTH, '[LOGIN] Bắt đầu đăng nhập với email: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật trạng thái online sử dụng hàm updateUserStatus
      await updateUserStatus(true);
      await _fcmService.saveTokenToUser(credential.user!.uid);

      logInfo(LogService.AUTH, '[LOGIN] Đăng nhập thành công: $email');
      return credential;
    } on FirebaseAuthException catch (e) {
      logError(LogService.AUTH, '[LOGIN] Lỗi đăng nhập: ${e.message}', e,
          StackTrace.current);
      throw Exception(e.message ?? 'Đăng nhập thất bại');
    }
  }

  /// Kiểm tra xem thông tin profile của người dùng đã đầy đủ chưa.
  ///
  /// Kiểm tra các trường bắt buộc:
  /// - Họ tên
  /// - Số điện thoại
  /// - Ngày sinh
  /// - Giới tính
  ///
  /// Returns `true` nếu tất cả thông tin đã đầy đủ.
  ///
  /// Throws [Exception] nếu không thể kiểm tra thông tin.
  Future<bool> isCompleteProfile() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        logWarning(LogService.AUTH,
            '[PROFILE] Không thể kiểm tra thông tin: người dùng chưa đăng nhập');
        throw Exception('Không tìm thấy người dùng');
      }

      logDebug(LogService.AUTH,
          '[PROFILE] Kiểm tra thông tin profile của người dùng: ${currentUser.uid}');

      final userDoc = await _users.doc(currentUser.uid).get();
      if (!userDoc.exists) {
        logWarning(LogService.AUTH,
            '[PROFILE] Không tìm thấy document thông tin người dùng: ${currentUser.uid}');
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Kiểm tra từng trường bắt buộc
      final checks = {
        'fullName': userData['fullName']?.toString().trim().isNotEmpty == true,
        'phoneNumber':
            userData['phoneNumber']?.toString().trim().isNotEmpty == true,
        'birthDay': userData['birthDay'] != null,
        'gender': userData['gender']?.toString().trim().isNotEmpty == true,
      };

      final isComplete = checks.values.every((isValid) => isValid);
      logInfo(LogService.AUTH,
          '[PROFILE] Kết quả kiểm tra thông tin người dùng ${currentUser.uid}: ${isComplete ? 'Đầy đủ' : 'Chưa đầy đủ'}');

      return isComplete;
    } catch (e) {
      logError(
          LogService.AUTH,
          '[PROFILE] Không thể kiểm tra thông tin người dùng',
          e,
          StackTrace.current);
      throw Exception(
          'Không thể kiểm tra thông tin người dùng: ${e.toString()}');
    }
  }

  /// Đăng xuất người dùng hiện tại.
  ///
  /// - Xóa FCM token
  /// - Đăng xuất khỏi Firebase Auth
  ///
  /// Throws [Exception] nếu không thể đăng xuất.
  Future<void> logout() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        logInfo(LogService.AUTH, '[LOGOUT] Đăng xuất người dùng: ${user.uid}');
        // Cập nhật trạng thái offline
        await updateUserStatus(false);

        await _fcmService.removeToken(user.uid);
      }

      // Đăng xuất khỏi Firebase Auth
      await _auth.signOut();
      logInfo(LogService.AUTH, '[LOGOUT] Đã đăng xuất thành công');
    } catch (e) {
      logError(
          LogService.AUTH, '[LOGOUT] Lỗi đăng xuất', e, StackTrace.current);
      // Vẫn đăng xuất ngay cả khi có lỗi
      await _auth.signOut();
      throw Exception('Đăng xuất thất bại: ${e.toString()}');
    }
  }

  /// Gửi email đặt lại mật khẩu.
  ///
  /// Parameters:
  /// - [email]: Email cần đặt lại mật khẩu
  ///
  /// Throws [Exception] nếu email không tồn tại hoặc có lỗi xảy ra.
  Future<void> resetPassword(String email) async {
    try {
      logInfo(
          LogService.AUTH, '[PASSWORD] Gửi email đặt lại mật khẩu đến: $email');
      await _auth.sendPasswordResetEmail(email: email);
      logInfo(LogService.AUTH,
          '[PASSWORD] Đã gửi email đặt lại mật khẩu thành công đến: $email');
    } catch (e) {
      logError(
          LogService.AUTH,
          '[PASSWORD] Lỗi gửi email đặt lại mật khẩu: $email',
          e,
          StackTrace.current);
      throw Exception('Lỗi gửi email đặt lại mật khẩu: ${e.toString()}');
    }
  }
}
