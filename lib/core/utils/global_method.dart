import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import '../services/permission/permission_service.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // Number of method calls to be displayed
    errorMethodCount: 8, // Number of method calls if stacktrace is provided
    lineLength: 120, // Width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    // Should each log print contain a timestamp
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

void showToastMessage({required String text}) {
  Fluttertoast.showToast(
    msg: text,
    textColor: Colors.black,
    backgroundColor: Colors.grey[500],
    fontSize: 16,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM, // Dịch lên 50dp từ bottom
  );
}

// tải ảnh lên firestore và trả về url
Future<String> uploadFileToFirebase({
  required File file,
  required String reference,
  Function(double)? onProgress,
}) async {
  try {
    UploadTask uploadTask =
        FirebaseStorage.instance.ref().child(reference).putFile(file);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (onProgress != null) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      }
    });

    TaskSnapshot taskSnapshot = await uploadTask;
    String fileUrl = await taskSnapshot.ref.getDownloadURL();

    return fileUrl;
  } catch (e) {
    logger.e('Lỗi khi tải tệp lên: $e');
    throw Exception('Lỗi khi tải tệp lên: $e');
  }
}

//pick image from gallery or camera
Future<File?> pickImage({
  required bool fromCamera,
  required Function(String) onFail,
}) async {
  File? fileImage;
  if (fromCamera) {
    //get image from camera
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return null;
      fileImage = File(image.path);
    } catch (e) {
      onFail(
        e.toString(),
      );
    }
  } else {
    //get image from gallery
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      fileImage = File(image.path);
    } catch (e) {
      onFail(
        e.toString(),
      );
    }
  }
  return fileImage;
}

// pick video  from gallery
Future<File?> pickVideo({
  required Function(String) onFail,
}) async {
  try {
    final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (video != null) {
      return File(video.path);
    } else {
      onFail("No video selected");
      return null;
    }
  } catch (e) {
    onFail(
      e.toString(),
    );
    return null;
  }
}

class ImagePickerHelper {
  File? _finalFileImage;
  File? get finalFileImage => _finalFileImage;

  void setfinalFileImage(File? file) {
    _finalFileImage = file;
  }

  // Khởi tạo PermissionService
  final PermissionService _permissionService = PermissionService();

  Future<bool> _requestPermission(bool fromCamera) async {
    final group = fromCamera ? PermissionGroup.media : PermissionGroup.storage;
    final status = await _permissionService.requestPermission(group);
    return status == AppPermissionStatus.granted;
  }

  String _getPermissionDeniedMessage(bool fromCamera) {
    return fromCamera
        ? 'permissions.camera_denied'.tr()
        : 'permissions.gallery_denied'.tr();
  }

  Future<void> selectImage({
    required bool fromCamera,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    // Kiểm tra quyền
    bool hasPermission = await _requestPermission(fromCamera);
    if (!hasPermission) {
      onError(_getPermissionDeniedMessage(fromCamera));
      return;
    }

    _finalFileImage = await pickImage(
      fromCamera: fromCamera,
      onFail: (String message) => onError(message),
    );

    if (_finalFileImage == null) return;

    await cropImage(
      filePath: _finalFileImage!.path,
      onSuccess: onSuccess,
    );
  }

  // Hiển thị dialog khi quyền bị từ chối
  Future<void> showPermissionDialog(BuildContext context, bool isCamera) async {
    final group = isCamera ? PermissionGroup.media : PermissionGroup.storage;

    final shouldOpenSettings =
        await _permissionService.showPermissionRationaleDialog(
      context,
      group,
    );

    if (shouldOpenSettings) {
      await _permissionService.openAppSettings();
    }
  }

  Future<void> cropImage({
    required String filePath,
    required Function() onSuccess,
  }) async {
    setfinalFileImage(File(filePath));
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      maxHeight: 800,
      maxWidth: 800,
      compressQuality: 90,
    );

    if (croppedFile != null) {
      setfinalFileImage(File(croppedFile.path));
      onSuccess();
    }
  }

  void showImagePickerBottomSheet({
    required BuildContext context,
    required Function() onSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('camera'.tr()),
              onTap: () {
                selectImage(
                  fromCamera: true,
                  onSuccess: () {
                    Navigator.pop(context);
                    onSuccess();
                  },
                  onError: (error) async {
                    showToastMessage(text: error);
                    // Nếu lỗi liên quan đến quyền, hiển thị dialog
                    if (error.contains('permissions')) {
                      Navigator.pop(context);
                      await showPermissionDialog(context, true);
                    }
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('gallery'.tr()),
              onTap: () {
                selectImage(
                  fromCamera: false,
                  onSuccess: () {
                    Navigator.pop(context);
                    onSuccess();
                  },
                  onError: (error) async {
                    showToastMessage(text: error);
                    // Nếu lỗi liên quan đến quyền, hiển thị dialog
                    if (error.contains('permissions')) {
                      Navigator.pop(context);
                      await showPermissionDialog(context, false);
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GlobalMethods {
  static final _logger = Logger();
  static final _picker = ImagePicker();

  // Image Handling Methods
  /// Chọn ảnh từ gallery hoặc camera
  /// [source]: ImageSource.gallery hoặc ImageSource.camera
  /// [maxSize]: Kích thước tối đa của ảnh (bytes)
  /// Returns: File ảnh đã chọn hoặc null nếu có lỗi
  static Future<File?> pickImage({
    required ImageSource source,
    int maxSize = 5 * 1024 * 1024,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      final size = await file.length();

      if (size > maxSize) {
        throw Exception('File size exceeds maximum limit of 5MB');
      }

      return file;
    } catch (e) {
      _logger.e('Error picking image: $e');
      return null;
    }
  }

  // Dialog Methods
  /// Hiển thị dialog chọn nguồn ảnh (gallery/camera)
  /// Returns: ImageSource đã chọn hoặc null nếu hủy
  static Future<ImageSource?> showImageSourceDialog(
      BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_source'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('gallery'.tr()),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('camera'.tr()),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  /// Hiển thị snackbar với message
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Date Formatting Methods
  /// Format DateTime thành chuỗi ngày tháng
  /// [date]: DateTime cần format
  /// [pattern]: Mẫu format (mặc định: dd/MM/yyyy)
  /// Returns: Chuỗi đã format
  static String formatDate(DateTime date, [String pattern = 'dd/MM/yyyy']) {
    try {
      return DateFormat(pattern).format(date);
    } catch (e) {
      _logger.e('Error formatting date: $e');
      return '';
    }
  }

  /// Tính tuổi từ ngày sinh
  /// Returns: Số tuổi hoặc 0 nếu có lỗi
  static int calculateAge(DateTime birthDate) {
    try {
      final today = DateTime.now();
      var age = today.year - birthDate.year;
      final monthDiff = today.month - birthDate.month;

      if (monthDiff < 0 || (monthDiff == 0 && today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      _logger.e('Error calculating age: $e');
      return 0;
    }
  }

  // Validation Methods
  /// Kiểm tra email có hợp lệ
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Kiểm tra số điện thoại có hợp lệ (Việt Nam)
  static bool isValidPhone(String phone) {
    return RegExp(r'^(\+84|0)[1-9][0-9]{8,9}$').hasMatch(phone);
  }

  // Error Handling Methods
  /// Xử lý và hiển thị lỗi
  static void handleError(BuildContext context, dynamic error) {
    _logger.e('Error occurred: $error');
    showSnackBar(
      context,
      message: error.toString(),
      isError: true,
    );
  }
}
