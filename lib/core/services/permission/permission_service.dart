import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

/// Enum định nghĩa các nhóm quyền trong ứng dụng
enum PermissionGroup {
  /// Nhóm quyền liên quan đến media (camera, gallery)
  media,

  /// Nhóm quyền liên quan đến thông báo
  notification,

  /// Nhóm quyền liên quan đến ghi âm
  audio,

  /// Nhóm quyền liên quan đến lưu trữ
  storage,

  /// Nhóm quyền liên quan đến vị trí
  location,
}

/// Kết quả của việc yêu cầu quyền
enum AppPermissionStatus {
  /// Quyền đã được cấp
  granted,

  /// Quyền bị từ chối, có thể yêu cầu lại
  denied,

  /// Quyền bị từ chối vĩnh viễn (không thể yêu cầu lại)
  permanentlyDenied,

  /// Quyền bị hạn chế (chỉ iOS)
  restricted,

  /// Chưa xác định
  unknown,
}

/// Service quản lý quyền truy cập trong ứng dụng
///
/// Cung cấp các phương thức để:
/// - Kiểm tra quyền truy cập
/// - Yêu cầu quyền truy cập
/// - Quản lý trạng thái quyền truy cập
/// - Xử lý khi quyền bị từ chối
class PermissionService {
  // Singleton pattern
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Key để lưu trạng thái đã yêu cầu quyền
  static const String _permissionRequestedKey = 'permission_requested';

  /// Kiểm tra và yêu cầu quyền truy cập dựa trên nhóm quyền
  Future<AppPermissionStatus> requestPermission(PermissionGroup group) async {
    try {
      // Xác định danh sách quyền cần yêu cầu dựa trên nhóm
      final permissions = _getPermissionsForGroup(group);

      // Kiểm tra từng quyền trong nhóm
      for (final permission in permissions) {
        final status = await _checkAndRequestPermission(permission);

        // Nếu có bất kỳ quyền nào bị từ chối, trả về trạng thái tương ứng
        if (status != AppPermissionStatus.granted) {
          return status;
        }
      }

      // Tất cả quyền đều được cấp
      return AppPermissionStatus.granted;
    } catch (e) {
      debugPrint('Lỗi khi yêu cầu quyền: $e');
      return AppPermissionStatus.unknown;
    }
  }

  /// Kiểm tra trạng thái hiện tại của quyền mà không yêu cầu
  Future<AppPermissionStatus> checkPermission(PermissionGroup group) async {
    try {
      final permissions = _getPermissionsForGroup(group);

      // Kiểm tra từng quyền trong nhóm
      for (final permission in permissions) {
        final status = await permission.status;

        // Chuyển đổi từ status của permission_handler sang AppPermissionStatus của chúng ta
        final ourStatus = _mapPermissionStatus(status);

        // Nếu có bất kỳ quyền nào không được cấp, trả về trạng thái tương ứng
        if (ourStatus != AppPermissionStatus.granted) {
          return ourStatus;
        }
      }

      return AppPermissionStatus.granted;
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra quyền: $e');
      return AppPermissionStatus.unknown;
    }
  }

  /// Hiển thị dialog giải thích khi quyền bị từ chối
  Future<bool> showPermissionRationaleDialog(
    BuildContext context,
    PermissionGroup group,
  ) async {
    final message = _getPermissionRationaleMessage(group);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('permissions.request_title'.tr()),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('common.cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('permissions.settings'.tr()),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Mở cài đặt ứng dụng
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Kiểm tra xem quyền đã được yêu cầu trước đó chưa
  Future<bool> hasRequestedPermission(PermissionGroup group) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_permissionRequestedKey:${group.name}') ?? false;
  }

  /// Đánh dấu quyền đã được yêu cầu
  Future<void> markPermissionRequested(PermissionGroup group) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_permissionRequestedKey:${group.name}', true);
  }

  /// Lấy danh sách quyền cho từng nhóm
  List<Permission> _getPermissionsForGroup(PermissionGroup group) {
    switch (group) {
      case PermissionGroup.media:
        return [Permission.camera, Permission.photos, Permission.storage];
      case PermissionGroup.notification:
        return [Permission.notification];
      case PermissionGroup.audio:
        return [Permission.microphone];
      case PermissionGroup.storage:
        return [Permission.storage];
      case PermissionGroup.location:
        return [Permission.location];
    }
  }

  /// Chuyển đổi status từ permission_handler sang AppPermissionStatus của chúng ta
  AppPermissionStatus _mapPermissionStatus(PermissionStatus status) {
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isDenied) return AppPermissionStatus.denied;
    if (status.isPermanentlyDenied)
      return AppPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return AppPermissionStatus.restricted;
    return AppPermissionStatus.unknown;
  }

  /// Lấy thông báo giải thích cho từng nhóm quyền
  String _getPermissionRationaleMessage(PermissionGroup group) {
    switch (group) {
      case PermissionGroup.media:
        return 'permissions.media_rationale'.tr();
      case PermissionGroup.notification:
        return 'permissions.notification_rationale'.tr();
      case PermissionGroup.audio:
        return 'permissions.audio_rationale'.tr();
      case PermissionGroup.storage:
        return 'permissions.storage_rationale'.tr();
      case PermissionGroup.location:
        return 'permissions.location_rationale'.tr();
    }
  }

  /// Kiểm tra và yêu cầu một quyền cụ thể
  Future<AppPermissionStatus> _checkAndRequestPermission(
      Permission permission) async {
    final status = await permission.status;

    if (status.isGranted) {
      return AppPermissionStatus.granted;
    }

    if (status.isDenied) {
      final result = await permission.request();
      return _mapPermissionStatus(result);
    }

    return _mapPermissionStatus(status);
  }
}

/// Provider cho PermissionService
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// Provider để kiểm tra quyền theo nhóm
final checkPermissionProvider =
    FutureProvider.family<AppPermissionStatus, PermissionGroup>(
  (ref, group) async {
    final permissionService = ref.watch(permissionServiceProvider);
    return permissionService.checkPermission(group);
  },
);
